# -*- encoding: utf-8 -*-
require 'httpclient'
require 'json'
require 'cgi'
require 'pp'

module GrowthForecast
  class Error < StandardError; end
  class NotFound < Error; end
  class AlreadyExists < Error; end

  class Client
    attr_accessor :debug
    attr_accessor :client
    attr_reader   :base_uri
    attr_accessor :keepalive

    # @param [String] base_uri The base uri of GrowthForecast
    def initialize(base_uri = 'http://127.0.0.1:5125', opts = {})
      @client = HTTPClient.new
      @base_uri = base_uri
      opts = stringify_keys(opts)
      @keepalive = opts.delete('keepalive') # bool
      self.debug_dev  = opts.delete('debug_dev') # IO object such as STDOUT
      # cf. https://github.com/nahi/httpclient/blob/0a16401e7892fbbd195a0254344bd48ac8a8bb26/lib/httpclient/session.rb#L133-L139
      # self.connect_timeout = 60
      # self.connect_retry = 1
      # self.send_timeout = 120
      # self.receive_timeout = 60        # For each read_block_size bytes
      # self.keep_alive_timeout = 15     # '15' is from Apache 2 default
      # self.read_block_size = 1024 * 16 # follows net/http change in 1.8.7
      # self.protocol_retry_count = 5
    end

    def stringify_keys(hash)
      {}.tap {|h| hash.each {|key, val| h[key.to_s] = val } }
    end

    class << self
      def attr_proxy_reader(symbol)
        attr_proxy(symbol)
      end

      def attr_proxy_accessor(symbol)
        attr_proxy(symbol, true)
      end

      def attr_proxy(symbol, assignable = false)
        name = symbol.to_s
        define_method(name) {
          @client.__send__(name)
        }
        if assignable
          aname = name + '='
          define_method(aname) { |rhs|
            @client.__send__(aname, rhs)
          }
        end
      end
    end

    # cf. https://github.com/nahi/httpclient/blob/0a16401e7892fbbd195a0254344bd48ac8a8bb26/lib/httpclient.rb#L309-L355
    # cf. https://github.com/nahi/httpclient/blob/0a16401e7892fbbd195a0254344bd48ac8a8bb26/lib/httpclient/session.rb#L89-L158
    # proxy::SSLConfig:: SSL configurator.
    attr_proxy_reader :ssl_config
    # WebAgent::CookieManager:: Cookies configurator.
    attr_proxy_accessor :cookie_manager
    # An array of response HTTP message body String which is used for loop-back
    # test.  See test/* to see how to use it.  If you want to do loop-back test
    # of HTTP header, use test_loopback_http_response instead.
    attr_proxy_reader :test_loopback_response
    # An array of request filter which can trap HTTP request/response.
    # See proxy::WWWAuth to see how to use it.
    attr_proxy_reader :request_filter
    # proxy::ProxyAuth:: Proxy authentication handler.
    attr_proxy_reader :proxy_auth
    # proxy::WWWAuth:: WWW authentication handler.
    attr_proxy_reader :www_auth
    # How many times get_content and post_content follows HTTP redirect.
    # 10 by default.
    attr_proxy_accessor :follow_redirect_count

    # Set HTTP version as a String:: 'HTTP/1.0' or 'HTTP/1.1'
    attr_proxy(:protocol_version, true)
    # Connect timeout in sec.
    attr_proxy(:connect_timeout, true)
    # Request sending timeout in sec.
    attr_proxy(:send_timeout, true)
    # Response receiving timeout in sec.
    attr_proxy(:receive_timeout, true)
    # Reuse the same connection within this timeout in sec. from last used.
    attr_proxy(:keep_alive_timeout, true)
    # Size of reading block for non-chunked response.
    attr_proxy(:read_block_size, true)
    # Negotiation retry count for authentication.  5 by default.
    attr_proxy(:protocol_retry_count, true)
    # if your ruby is older than 2005-09-06, do not set socket_sync = false to
    # avoid an SSL socket blocking bug in openssl/buffering.rb.
    attr_proxy(:socket_sync, true)
    # User-Agent header in HTTP request.
    attr_proxy(:agent_name, true)
    # From header in HTTP request.
    attr_proxy(:from, true)
    # An array of response HTTP String (not a HTTP message body) which is used
    # for loopback test.  See test/* to see how to use it.
    attr_proxy(:test_loopback_http_response)
    # Decompress a compressed (with gzip or deflate) content body transparently. false by default.
    attr_proxy(:transparent_gzip_decompression, true)
    # Local socket address. Set HTTPClient#socket_local.host and HTTPClient#socket_local.port to specify local binding hostname and port of TCP socket.
    attr_proxy(:socket_local, true)

    # cf. https://github.com/nahi/httpclient/blob/0a16401e7892fbbd195a0254344bd48ac8a8bb26/lib/httpclient.rb#L416-L569
    attr_proxy_accessor :debug_dev
    attr_proxy_accessor :proxy
    attr_proxy_accessor :no_proxy
    def set_auth(domain, user, passwd)
      @client.set_auth(domain, user, passwd)
    end
    def set_basic_auth(domain, user, passwd)
      @client.set_basic_auth(domain, user, passwd)
    end
    def set_proxy_auth(user, passwd)
      @client.set_proxy_auth(user, passwd)
    end
    def set_cookie_store(filename)
      @client.set_cookie_store(filename)
    end
    attr_proxy_reader :save_cookie_store
    attr_proxy_reader :cookies
    attr_proxy_accessor :redirect_uri_callback

    def last_request_uri
      @request_uri
    end

    def last_response
      @res
    end

    # GET the JSON API
    # @param [String] path
    # @return [Hash] response body
    def get_json(path)
      @request_uri = "#{@base_uri}#{path}" 
      query = nil
      extheader = @keepalive ? { 'Connection' => 'Keep-Alive' } : {}
      @res = client.get(@request_uri, query, extheader)
      handle_error(@res)
      JSON.parse(@res.body)
    end

    # POST the JSON API
    # @param [String] path
    # @param [Hash] data 
    # @return [Hash] response body
    def post_json(path, data = {})
      pp data if @debug
      @request_uri = "#{@base_uri}#{path}" 
      json = JSON.generate(data)
      extheader = @keepalive ? { 'Connection' => 'Keep-Alive' } : {}
      @res = client.post(@request_uri, json, extheader)
      handle_error(@res)
      JSON.parse(@res.body)
    end

    # POST the non-JSON API
    # @param [String] path
    # @param [Hash] data 
    # @return [String] response body
    def post_query(path, data = {})
      pp data if @debug
      @request_uri = "#{@base_uri}#{path}" 
      extheader = @keepalive ? { 'Connection' => 'Keep-Alive' } : {}
      @res = client.post(@request_uri, data, extheader)
      handle_error(@res)
      JSON.parse(@res.body)
    end

    # Get the list of graphs, /json/list/graph
    # @return [Hash] list of graphs
    # @example
    # [
    #   {"service_name"=>"test",
    #    "graph_name"=>"<2sec_count",
    #    "section_name"=>"hostname",
    #    "id"=>4},
    #   {"service_name"=>"test",
    #    "graph_name"=>"<1sec_count",
    #    "section_name"=>"hostname",
    #    "id"=>3},
    # ]
    def list_graph(service_name = nil, section_name = nil, graph_name = nil)
      graphs = get_json('/json/list/graph')
      graphs = graphs.select {|g| g['service_name'] == service_name } if service_name
      graphs = graphs.select {|g| g['section_name'] == section_name } if section_name
      graphs = graphs.select {|g| g['graph_name']   == graph_name   } if graph_name
      graphs
    end

    # A Helper: Get the list of section
    # @return [Hash] list of sections
    # @example
    # {
    #   "service_name1" => [
    #     "section_name1",
    #     "section_name2",
    #   ],
    #   "service_name2" => [
    #     "section_name1",
    #     "section_name2",
    #   ],
    # }
    def list_section(service_name = nil, section_name = nil, graph_name = nil)
      graphs = list_graph(service_name, section_name, graph_name)
      services = {}
      graphs.each do |graph|
        service_name, section_name = graph['service_name'], graph['section_name']
        services[service_name] ||= {}
        services[service_name][section_name] ||= true
      end
      Hash[services.map {|service_name, sections| [service_name, sections.keys] }]
    end

    # A Helper: Get the list of services
    # @return [Array] list of services
    # @example
    # [
    #   "service_name1",
    #   "service_name2",
    # ]
    def list_service(service_name = nil, section_name = nil, graph_name = nil)
      graphs = list_graph(service_name, section_name, graph_name)
      services = {}
      graphs.each do |graph|
        service_name = graph['service_name']
        services[service_name] ||= true
      end
      services.keys
    end

    # Post parameters to a graph, POST /api/:service_name/:section_name/:graph_name
    # @param [String] service_name
    # @param [String] section_name
    # @param [String] graph_name
    # @param [Hash] params The POST parameters. See #get_graph
    # @return [Hash] the error code and graph property
    # @example
    #{"error"=>0,
    #"data"=>{
    #  "number"=>1,
    #  "llimit"=>-1000000000,
    #  "mode"=>"gauge",
    #  "stype"=>"AREA",
    #  "adjustval"=>"1",
    #  "meta"=>"",
    #  "service_name"=>"test",
    #  "gmode"=>"gauge",
    #  "color"=>"#cc6633",
    #  "created_at"=>"2013/02/02 00:41:11",
    #  "section_name"=>"hostname",
    #  "ulimit"=>1000000000,
    #  "id"=>21,
    #  "graph_name"=>"<4sec_count",
    #  "description"=>"",
    #  "sulimit"=>100000,
    #  "unit"=>"",
    #  "sort"=>0,
    #  "updated_at"=>"2013/02/02 02:32:10",
    #  "adjust"=>"*",
    #  "type"=>"AREA",
    #  "sllimit"=>-100000,
    #  "md5"=>"3c59dc048e8850243be8079a5c74d079"}}
    def post_graph(service_name, section_name, graph_name, params)
      post_query("/api/#{e service_name}/#{e section_name}/#{e graph_name}", params)
    end

    # Get the propety of a graph, GET /api/:service_name/:section_name/:graph_name
    # @param [String] service_name
    # @param [String] section_name
    # @param [String] graph_name
    # @return [Hash] the graph property
    # @example
    #{
    #  "number"=>1,
    #  "llimit"=>-1000000000,
    #  "mode"=>"gauge",
    #  "stype"=>"AREA",
    #  "adjustval"=>"1",
    #  "meta"=>"",
    #  "service_name"=>"test",
    #  "gmode"=>"gauge",
    #  "color"=>"#cc6633",
    #  "created_at"=>"2013/02/02 00:41:11",
    #  "section_name"=>"hostname",
    #  "ulimit"=>1000000000,
    #  "id"=>21,
    #  "graph_name"=>"<4sec_count",
    #  "description"=>"",
    #  "sulimit"=>100000,
    #  "unit"=>"",
    #  "sort"=>0,
    #  "updated_at"=>"2013/02/02 02:32:10",
    #  "adjust"=>"*",
    #  "type"=>"AREA",
    #  "sllimit"=>-100000,
    #  "md5"=>"3c59dc048e8850243be8079a5c74d079"}
    def get_graph(service_name, section_name, graph_name)
      get_json("/api/#{e service_name}/#{e section_name}/#{e graph_name}")
    end

    # Get the propety of a graph, /json/graph/:id
    # @param [String] id
    # @return [Hash] the graph property
    # @example
    # {"llimit"=>-1000000000,
    #  "number"=>48778224,
    #  "stype"=>"AREA",
    #  "mode"=>"count",
    #  "complex"=>false,
    #  "adjustval"=>"1",
    #  "created_at"=>"2013/02/01 16:01:17",
    #  "color"=>"#cc3366",
    #  "service_name"=>"test",
    #  "gmode"=>"gauge",
    #  "ulimit"=>1000000000,
    #  "section_name"=>"all",
    #  "id"=>1,
    #  "graph_name"=>"response_time_max",
    #  "description"=>"",
    #  "sort"=>0,
    #  "unit"=>"",
    #  "sulimit"=>100000,
    #  "updated_at"=>"2013/02/04 18:26:49",
    #  "adjust"=>"*",
    #  "sllimit"=>-100000,
    #  "type"=>"AREA"}
    def get_graph_by_id(id)
      get_json("/json/graph/#{id}")
    end

    # Delete a graph, POST /delete/:service_name/:section_name/:graph_name
    # @param [String] service_name
    # @param [String] section_name
    # @param [String] graph_name
    def delete_graph(service_name, section_name, graph_name)
      post_query("/delete/#{e service_name}/#{e section_name}/#{e graph_name}")
    end

    # Delete a graph, POST /json/delete/graph/:id
    # @param [String] id
    def delete_graph_by_id(id)
      post_query("/json/delete/graph/#{id}")
    end

    # Update the property of a graph, /json/edit/graph/:id
    # @param [String] service_name
    # @param [String] section_name
    # @param [String] graph_name
    # @param [Hash]   params
    #   All of parameters given by #get_graph are available except `number` and `mode`.
    # @return [Hash]  error response
    # @example
    # {"error"=>0} #=> Success
    # {"error"=>1} #=> Error
    def edit_graph(service_name, section_name, graph_name, params)
      data = get_graph(service_name, section_name, graph_name)
      id = data['id']
      updates = handle_update_params(data, params)
      post_json("/json/edit/graph/#{id}", updates)
    end

    # Get the list of complex graphs, /json/list/complex
    # @return [Hash] list of complex graphs
    # @example
    # [
    #   {"service_name"=>"test",
    #    "graph_name"=>"<2sec_count",
    #    "section_name"=>"hostname",
    #    "id"=>4},
    #   {"service_name"=>"test",
    #    "graph_name"=>"<1sec_count",
    #    "section_name"=>"hostname",
    #    "id"=>3},
    # ]
    def list_complex(service_name = nil, section_name = nil, graph_name = nil)
      graphs = get_json('/json/list/complex')
      graphs = graphs.select {|g| g['service_name'] == service_name } if service_name
      graphs = graphs.select {|g| g['section_name'] == section_name } if section_name
      graphs = graphs.select {|g| g['graph_name']   == graph_name   } if graph_name
      graphs
    end

    # Create a complex graph
    #
    # @param [Array] from_graphs Array of graph properties whose keys are
    #   ["service_name", "section_name", "graph_name", "gmode", "stack", "type"]
    # @param [Hash] to_complex Property of Complex Graph, whose keys are like
    #   ["service_name", "section_name", "graph_name", "description", "sort"]
    def create_complex(from_graphs, to_complex)
      graph_data = []
      from_graphs.each do |from_graph|
        graph = get_graph(from_graph["service_name"], from_graph["section_name"], from_graph["graph_name"])
        graph_id = graph['id']

        graph_data << {
          :gmode    => from_graph["gmode"],
          :stack    => from_graph["stack"],
          :type     => from_graph["type"],
          :graph_id => graph_id
        }
      end

      post_params = {
        :service_name => to_complex["service_name"],
        :section_name => to_complex["section_name"],
        :graph_name   => to_complex["graph_name"],
        :description  => to_complex["description"],
        :sort         => to_complex["sort"],
        :data         => graph_data
      }
      post_json('/json/create/complex', post_params)
    end

    # Get the propety of a complex graph, GET /json/complex/:service_name/:section_name/:graph_name
    # @param [String] service_name
    # @param [String] section_name
    # @param [String] graph_name
    # @return [Hash] the graph property
    # @version 0.70 or more
    # @example
    # {"number"=>0,
    #  "complex"=>true,
    #  "created_at"=>"2013/05/20 15:08:28",
    #  "service_name"=>"app name",
    #  "section_name"=>"host name",
    #  "id"=>18,
    #  "graph_name"=>"complex graph test",
    #  "data"=>
    #   [{"gmode"=>"gauge", "stack"=>false, "type"=>"AREA", "graph_id"=>218},
    #    {"gmode"=>"gauge", "stack"=>true, "type"=>"AREA", "graph_id"=>217}],
    #  "sumup"=>false,
    #  "description"=>"complex graph test",
    #  "sort"=>10,
    #  "updated_at"=>"2013/05/20 15:08:28"}
    def get_complex(service_name, section_name, graph_name)
      get_json("/json/complex/#{e service_name}/#{e section_name}/#{e graph_name}")
    end

    # Get the propety of a complex graph, GET /json/complex/:id
    # @param [String] id
    # @return [Hash] the graph property
    # @version 0.70 or more
    # @example See #get_complex
    def get_complex_by_id(id)
      get_json("/json/complex/#{id}")
    end

    # Delete a complex graph
    #
    # This is a helper method of GrowthForecast API to find complex graph id and call delete_complex_by_id
    #
    # @param [String] service_name
    # @param [String] section_name
    # @param [String] graph_name
    # @return [Hash]  error response
    # @example
    # {"error"=>0} #=> Success
    # {"error"=>1} #=> Error
    def delete_complex(service_name, section_name, graph_name)
      post_query("/json/delete/complex/#{e service_name}/#{e section_name}/#{e graph_name}")
    end

    # Delete a complex graph, /delete_complex/:complex_id
    #
    # @param [String] id of a complex graph
    # @return [Hash]  error response
    # @example
    # {"error"=>0} #=> Success
    # {"error"=>1} #=> Error
    def delete_complex_by_id(complex_id)
      post_query("/delete_complex/#{complex_id}")
    end

    private

    def e(str)
      CGI.escape(str).gsub('+', '%20') if str
    end

    def handle_error(res)
      case res.status
      when 200
      when 404
        raise NotFound.new(error_message(res))
      when 409
        raise AlreadyExists.new(error_message(res))
      else
        raise Error.new(error_message(res))
      end
    end

    def error_message(res)
      "status:#{res.status}\turi:#{res.http_header.request_uri.to_s}\tmessage:#{res.body}"
    end

    # GrowthForecast's /json/edit/graph API requires all parameters to update, thus
    # we have to merge the original graph parameters and parameters which we want to update. Sucks!
    #
    # @param [Hash] graph_data the current graph property data
    # @param [Hash[ params     the parameters which we want to update
    # @return [Hash] merged parameters
    def handle_update_params(graph_data, params)
      updates = graph_data.merge(params)
      # `meta` field is automatically added when we call get_graph.
      # If we post `meta` data to update graph, `meta` is constructed circularly. Sucks!
      # Thus, I remove the `meta` here.
      updates['meta'] = '' if !params.has_key?('meta')
      updates
    end
  end
end

