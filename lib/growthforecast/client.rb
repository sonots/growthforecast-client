# -*- encoding: utf-8 -*-
require 'net/http'
require 'net/https'
require 'uri'
require 'json'
require 'cgi'

module GrowthForecast
  class Error < StandardError; end
  class NotFound < Error; end
  class AlreadyExists < Error; end

  class Client
    attr_reader   :base_uri
    attr_reader   :host
    attr_reader   :port
    attr_accessor :debug_dev
    attr_accessor :open_timeout
    attr_accessor :read_timeout
    attr_accessor :verify_ssl
    attr_accessor :keepalive

    # @param [String] base_uri The base uri of GrowthForecast
    def initialize(base_uri = 'http://127.0.0.1:5125', opts = {})
      @base_uri = base_uri
      opts = stringify_keys(opts)

      URI.parse(base_uri).tap {|uri|
        @host       = uri.host
        @port       = uri.port
        @use_ssl    = uri.scheme == 'https'
      }
      @debug_dev    = opts['debug_dev'] # IO object such as STDOUT
      @open_timeout = opts['open_timeout'] # 60
      @read_timeout = opts['read_timeout'] # 60
      @keepalive    = opts['keepalive']
      @verify_ssl   = opts['verify_ssl']
      @ca_file      = opts['ca_file']
    end

    def http_connection
      Net::HTTP.new(@host, @port).tap {|http|
        http.use_ssl      = @use_ssl
        http.open_timeout = @open_timeout if @open_timeout
        http.read_timeout = @read_timeout if @read_timeout
        if @verify_ssl
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
          http.ca_file     = @ca_file if @ca_file
        else
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        http.set_debug_output(@debug_dev) if @debug_dev
      }
    end

    def get_request(path, extheader = {})
      Net::HTTP::Get.new(path).tap {|req|
        req['Host'] = @host
        req['Connection'] = 'Keep-Alive' if @keepalive
        extheader.each {|key, value| req[key] = value }
      }
    end

    def post_request(path, body, extheader = {})
      Net::HTTP::Post.new(path).tap {|req|
        req['Host'] = @host
        req['Connection'] = 'Keep-Alive' if @keepalive
        extheader.each {|key, value| req[key] = value }
        req.body = body
      }
    end

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
      req  = get_request(path)
      @res = http_connection.start {|http| http.request(req) }
      handle_error(@res, @request_uri)
      JSON.parse(@res.body)
    end

    # POST the JSON API
    # @param [String] path
    # @param [Hash] data 
    # @return [Hash] response body
    def post_json(path, data = {})
      @request_uri = "#{@base_uri}#{path}" 
      body = JSON.generate(data)
      extheader = { 'Content-Type' => 'application/json' }
      req  = post_request(path, body, extheader)
      @res = http_connection.start {|http| http.request(req) }
      handle_error(@res, @request_uri)
      JSON.parse(@res.body)
    end

    # POST the non-JSON API
    # @param [String] path
    # @param [Hash] data 
    # @return [String] response body
    def post_query(path, data = {})
      @request_uri = "#{@base_uri}#{path}" 
      body = URI.encode_www_form(data)
      extheader = { 'Content-Type' => 'application/x-www-form-urlencoded' }
      req  = post_request(path, body, extheader)
      @res = http_connection.start {|http| http.request(req) }
      handle_error(@res, @request_uri)
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

    # Post parameters to a vrule, POST /vrule/api/:service_name/:section_name/:graph_name
    # @param [String] service_name
    # @param [String] section_name
    # @param [String] graph_name
    # @param [Hash] params The POST parameters. See #get_vrule
    # @return [Hash] the error code and graph property
    # @example
    #{"error"=>0,
    #"data"=>{
    #  "graph_path"=>"/hoge/hoge/hoge",
    #  "color"=>"#FF0000",
    #  "time"=>1395826210,
    #  "id"=>1,
    #  "dashes"=>"2,10",
    #  "description"=>""}}
    def post_vrule(service_name = nil, section_name = nil, graph_name = nil, params = {})
      path = "/vrule/api"
      path += "/#{e service_name}" if service_name
      path += "/#{e section_name}" if section_name
      path += "/#{e graph_name}"   if graph_name
      post_query(path, params)
    end

    # Get the data of vrules, GET /vrule/summary/:service_name/:section_name/:graph_name
    # @param [String] service_name
    # @param [String] section_name
    # @param [String] graph_name
    # @return [Hash] the data of vrules
    # @example
    #[
    #{
    #  "graph_path"=>"/hoge/hoge/hoge",
    #  "color"=>"#FF0000",
    #  "time"=>1395826210,
    #  "id"=>1,
    #  "dashes"=>"",
    #  "description"=>""
    #},
    #{
    #  "graph_path"=>"/hoge/hoge/hoge",
    #  "color"=>"#FF0000",
    #  "time"=>1395826363,
    #  "id"=>2,
    #  "dashes"=>"2,10",
    #  "description"=>""
    #}
    #]
    def get_vrule(service_name = nil, section_name = nil, graph_name = nil)
      path = "/vrule/summary"
      path += "/#{e service_name}" if service_name
      path += "/#{e section_name}" if section_name
      path += "/#{e graph_name}"   if graph_name
      get_json(path)
    end

    private

    def e(str)
      CGI.escape(str).gsub('+', '%20') if str
    end

    def handle_error(res, request_uri)
      case res.code
      when '200'
      when '404'
        raise NotFound.new(error_message(res, request_uri))
      when '409'
        raise AlreadyExists.new(error_message(res, request_uri))
      else
        raise Error.new(error_message(res, request_uri))
      end
    end

    def error_message(res, request_uri)
      "status:#{res.code}\turi:#{request_uri}\tmessage:#{res.body}"
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

    def stringify_keys(hash)
      {}.tap {|h| hash.each {|key, val| h[key.to_s] = val } }
    end
  end
end

