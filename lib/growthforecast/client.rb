# -*- encoding: utf-8 -*-
require 'httpclient'
require 'json'
require 'uri'
require 'pp'

module GrowthForecast
  class Error < StandardError; end
  class NotFound < Error; end
  class AlreadyExists < Error; end
  attr_accessor :debug

  class Client
    # @param [String] base_uri The base uri of GrowthForecast
    def initialize(base_uri)
      @base_uri = base_uri
    end

    # GET the JSON API
    # @param [String] path
    # @return [Hash] response body
    def get_json(path)
      res = client.get("#{@base_uri}#{path}")
      handle_error(res)
      JSON.parse(res.body)
    end

    # POST the JSON API
    # @param [String] path
    # @param [Hash] data 
    # @return [Hash] response body
    def post_json(path, data)
      pp data if @debug
      json = JSON.generate(data)
      res = client.post("#{@base_uri}#{path}", json)
      handle_error(res)
      JSON.parse(res.body)
    end

    # POST the non-JSON API
    # @param [String] path
    # @param [Hash] data 
    # @return [String] response body
    def post_query(path, data)
      pp data if @debug
      res = client.post("#{@base_uri}#{path}", data)
      handle_error(res)
      res.body
    end

    # Get the list of graphs, /json/list/graph
    # @return [Hash] list of graphs
    # @example
    # [
    #   {"service_name"=>"test",
    #    "graph_name"=>"response_count_lt_2",
    #    "section_name"=>"gowdev5004",
    #    "id"=>4},
    #   {"service_name"=>"test",
    #    "graph_name"=>"response_count_lt_1",
    #    "section_name"=>"gowdev5004",
    #    "id"=>3},
    # ]
    def list_graph
      get_json('/json/list/graph')
    end

    # Get the propety of a graph, /api/:service_name/:section_name/:graph_name
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
    #  "section_name"=>"gowdev5004",
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
      get_json("/api/#{service_name}/#{section_name}/#{graph_name}")
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

    # Update the property of a graph, /json/edit/graph/:id
    # @param [String] service_name
    # @param [String] section_name
    # @param [String] graph_name
    # @param [Hash]   params See #get_graph for available parameters
    # @return [Hash]  error response
    # @example
    # {"error"=>0} #=> Success
    # {"error"=>1} #=> Error
    def update_graph(service_name, section_name, graph_name, params)
      data = get_graph(service_name, section_name, graph_name)
      id = data['id']
      updates = handle_update_params(data, params)
      pp updates if @debug
      post_json("/json/edit/graph/#{id}", updates)
    end

    # Update the property of a graph, /json/edit/graph/:id
    # @param [String] id
    # @param [Hash]   params See #get_graph for available parameters
    # @return [Hash]  error response
    # @example
    # {"error"=>0} #=> Success
    # {"error"=>1} #=> Error
    def update_graph_by_id(id, params)
      data = get_graph_by_id(id)
      updates = handle_update_params(data, params)
      pp updates if @debug
      post_json("/json/edit/graph/#{id}", updates)
    end

    # Create a complex graph
    #
    # @param [Array] from_graphs Array of graph properties. A graph property is like
    #   {path: "/:service_name/:section_name/:graph_name", gmode: "gauge", stack: true, type: 'AREA' }
    # @param [Hash] to_complex Property of Complex Graph, which is like
    #   {path: "/:service_name/:section_name/:graph_name", description: "description", sort: 10 }
    def create_complex(from_graphs, to_complex)
      graph_data = []
      from_graphs.each do |from_graph|
        service_name, section_name, graph_name = from_graph[:path].split('/')
        graph = get_graph(service_name, section_name, graph_name)
        graph_id = graph['id']

        graph_data << {
          :gmode    => from_graph[:gmode],
          :stack    => from_graph[:stack],
          :type     => from_graph[:type],
          :graph_id => graph_id
        }
      end

      to_service, to_section, to_graph = to_complex[:path].split('/')
      post_params = {
        :service_name => to_service,
        :section_name => to_section,
        :graph_name   => to_graph,
        :description  => to_complex[:description],
        :sort         => to_complex[:sort],
        :data         => graph_data
      }

      pp updates if @post_params
      post_json('/json/create/complex', post_params)
    end

    private

    def client
      @client ||= HTTPClient.new
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
      "status:#{res.status}\turi:#{res.http_header.request_uri.to_s}"
    end

    # GrowthForecast's /json/edit/graph API requires all parameters to update, thus
    # we have to merge the original graph parameters and parameters which we want to update. Sucks!
    #
    # @param [Hash] graph_data the current graph property data
    # @param [Hash[ params     the parameters which we want to update
    # @return [Hash] merged parameters
    def handle_update_params(graph_data, params)
      updates = graph_data.merge(params)
      # Do not post `number` when `mode` is `count` not to increment the number of graph.
      # But, post as is if the user specify `number` or `mode` in params. Sucks!
      updates['number'] = 0 if !params.has_key?('number') and updates['mode'] == 'count'
      # `meta` field is automatically added when we call get_graph.
      # If we post `meta` data to update graph, `meta` is constructed circularly. Sucks!
      # Thus, I remove the `meta` here.
      updates['meta'] = '' if !params.has_key?('meta')
      updates
    end
  end
end

