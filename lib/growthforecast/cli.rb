# -*- encoding: utf-8 -*-
require 'thor'

class GrowthForecast::CLI < Thor
  class_option :silent, :aliases => ["-S"], :type => :boolean

  def initialize(args = [], opts = [], config = {})
    super(args, opts, config)
  end

  desc 'delete <url>', 'delete a graph or graphs under a url'
  long_desc <<-LONGDESC
    Delete a graph or graphs under a <url> where <url> is the one obtained from the GrowthForecast URI, e.g., 
    http://{hostname}:{port}/list/{service_name}/{section_name}?t=sh
    or
    http://{hostname}:{port}/view_graph/{service_name}/{section_name}/{graph_name}?t=sh

    ex) growthforecast-client delete 'http://{hostname}:{port}/list/{service_name}/{section_name}'
  LONGDESC
  def delete(url)
    base_uri, service_name, section_name, graph_name = split_url(url)
    @client = client(base_uri)

    graphs = @client.list_graph(service_name, section_name, graph_name)
    delete_graphs(graphs)

    complexes = @client.list_complex(service_name, section_name, graph_name)
    delete_complexes(complexes)
  end

  desc 'color <url>', 'change the color of graphs'
  long_desc <<-LONGDESC
    Change the color of graphs

    ex) growthforecast-client color 'http://{hostname}:{port}/list/{service_name}/{section_name}' -c '2xx_count:#1111cc' '3xx_count:#11cc11'
  LONGDESC
  option :colors, :type => :hash,   :aliases => '-c', :required => true, :banner => 'GRAPH_NAME:COLOR ...'
  def color(url)
    colors = options[:colors]

    base_uri, service_name, section_name, graph_name = split_url(url)
    @client = client(base_uri)

    graphs = @client.list_graph(service_name, section_name, graph_name)
    setup_colors(colors, graphs)
  end

  desc 'create_complex <url>', 'create complex graphs'
  long_desc <<-LONGDESC
    Create complex graphs under a url

    ex) growthforecast-client create_complex 'http://{hostname}:{port}/list/{service_name}' -f 2xx_count 3xx_count -t status_count
  LONGDESC
  option :from_graphs, :type => :array,  :aliases => '-f', :required => true, :banner => 'GRAPH_NAMES ...'
  option :to_complex,  :type => :string, :aliases => '-t', :required => true
  def create_complex(url)
    from_graphs, to_complex = options[:from_graphs], options[:to_complex]
    base_uri, service_name, section_name, graph_name = split_url(url)
    @client = client(base_uri)

    graphs = @client.list_graph(service_name, section_name, graph_name)
    setup_complex(from_graphs, to_complex, graphs)
  end

  no_tasks do
    def delete_graphs(graphs)
      graphs.each do |graph|
        puts "Delete #{e graph['service_name']}/#{e graph['section_name']}/#{e graph['graph_name']}" unless @options[:silent]
        exec { @client.delete_graph(graph['service_name'], graph['section_name'], graph['graph_name']) }
      end
    end

    def delete_complexes(complexes)
      complexes.each do |graph|
        puts "Delete #{e graph['service_name']}/#{e graph['section_name']}/#{e graph['graph_name']}" unless @options[:silent]
        exec { @client.delete_complex(graph['service_name'], graph['section_name'], graph['graph_name']) }
      end
    end

    def setup_colors(colors, graphs)
      graphs.each do |graph|
        service_name, section_name, graph_name = graph['service_name'], graph['section_name'], graph['graph_name']
        next unless color = colors[graph_name]

        params = {
          'color'  => color,
          'unit'   => 'count',
          'sort'   => 1, # order to display, 19 is the top
          'adjust' => '/',
          'adjustval' => '1',
        }
        puts "Setup #{service_name}/#{section_name}/#{graph_name} with #{color}" unless @options[:silent]
        exec { @client.edit_graph(service_name, section_name, graph_name, params) }
      end
    end

    def setup_complex(from_graphs, to_complex, graphs)
      from_graph_first = from_graphs.first
      graphs.each do |graph|
        service_name, section_name, graph_name = graph['service_name'], graph['section_name'], graph['graph_name']
        next unless graph_name == from_graph_first

        base = { "service_name" => service_name, "section_name" => section_name, "gmode" => 'gauge', "stack" => true, "type" => 'AREA' }
        from_graphs_params = from_graphs.map {|graph_name| base.merge('graph_name' => graph_name) }
        to_complex_params = { "service_name" => service_name, "section_name" => section_name, "graph_name" => to_complex, "sort" => 1 }

        puts "Setup /#{service_name}/#{section_name}/#{to_complex} with #{from_graphs}" unless @options[:silent]
        exec { @client.create_complex(from_graphs_params, to_complex_params) }
      end
    end

    def exec(&blk)
      begin
        yield
      rescue => e
        $stderr.puts "\tclass:#{e.class}\t#{e.message}"
      end
    end

    def e(str)
      CGI.escape(str).gsub('+', '%20') if str
    end

    def client(base_uri)
      GrowthForecast::Client.new(base_uri)
    end

    def split_url(url)
      uri = URI.parse(url)
      base_uri = "#{uri.scheme}://#{uri.host}:#{uri.port}"
      [base_uri] + split_path(uri.path)
    end

    def split_path(path)
      path = path.gsub(/.*list\/?/, '').gsub(/.*view_graph\/?/, '')
      path.split('/').map {|p| CGI.unescape(p.gsub('%20', '+')) }
    end
  end
end

