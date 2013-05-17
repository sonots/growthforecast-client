# -*- encoding: utf-8 -*-
require 'httpclient'
require 'json'
require 'uri'
require 'pp'

module GrowthForecast
  class Error < StandardError; end
  class NotFound < Error; end
  class AlreadyExists < Error; end

  class Client
    attr_accessor :debug
    attr_accessor :client
    attr_reader   :base_uri

    # @param [String] base_uri The base uri of GrowthForecast
    def initialize(base_uri = 'http://127.0.0.1:5125')
      @base_uri = base_uri
    end

    def client
      @client ||= HTTPClient.new
    end

    def last_response
      @res
    end

    # GET the JSON API
    # @param [String] path
    # @return [Hash] response body
    def get_json(path)
      @res = client.get("#{@base_uri}#{path}")
      handle_error(@res)
      JSON.parse(@res.body)
    end

    # POST the JSON API
    # @param [String] path
    # @param [Hash] data 
    # @return [Hash] response body
    def post_json(path, data = {})
      pp data if @debug
      json = JSON.generate(data)
      @res = client.post("#{@base_uri}#{path}", json)
      handle_error(@res)
      JSON.parse(@res.body)
    end

    # POST the non-JSON API
    # @param [String] path
    # @param [Hash] data 
    # @return [String] response body
    def post_query(path, data = {})
      pp data if @debug
      @res = client.post("#{@base_uri}#{path}", data)
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
    def list_section
      graphs = list_graph
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
    def list_service
      graphs = list_graph
      services = {}
      graphs.each do |graph|
        service_name = graph['service_name']
        services[service_name] ||= true
      end
      services.keys
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

    # Post parameters to a graph, POST /api/:service_name/:section_name/:graph_name
    # @param [String] service_name
    # @param [String] section_name
    # @param [String] graph_name
    # @param [Hash] params The POST parameters. See #get_graph
    def post_graph(service_name, section_name, graph_name, params)
      post_query("/api/#{e service_name}/#{e section_name}/#{e graph_name}", params)
    end

    # Delete a graph, POST /delete/:service_name/:section_name/:graph_name
    # @param [String] service_name
    # @param [String] section_name
    # @param [String] graph_name
    def delete_graph(service_name, section_name, graph_name)
      post_query("/delete/#{e service_name}/#{e section_name}/#{e graph_name}")
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
      complex_graphs = list_complex
      complex = complex_graphs.select {|g| g["service_name"] == service_name and g["section_name"] == section_name and g["graph_name"] == graph_name }
      raise NotFound if complex.empty?
      delete_complex_by_id(complex.first["id"])
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
      URI.escape(str) if str
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

