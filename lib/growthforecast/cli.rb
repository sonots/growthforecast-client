# -*- encoding: utf-8 -*-
require 'thor'

class GrowthForecast::CLI < Thor
  class_option :silent, :aliases => ["-S"], :type => :boolean

  def initialize(args = [], opts = [], config = {})
    super(args, opts, config)
  end

  desc 'post <json> <api_url>', 'post a paramter to graph api'
  long_desc <<-LONGDESC
    Post a parameter to graph api

    ex) growthforecast-client post '{"number":0}' http://{hostname}:{port}/api/{service_name}/{section_name}/{graph_name}
  LONGDESC
  def post(json, url)
    base_uri, service_name, section_name, graph_name = split_url(url)
    @client = client(base_uri)
    puts @client.post_graph(service_name, section_name, graph_name, JSON.parse(json))
  end

  desc 'delete <url>', 'delete a graph or graphs under a url'
  long_desc <<-LONGDESC
    Delete a graph or graphs under a <url> where <url> is the one obtained from the GrowthForecast URI, e.g., 
    http://{hostname}:{port}/list/{service_name}/{section_name}?t=sh
    or
    http://{hostname}:{port}/view_graph/{service_name}/{section_name}/{graph_name}?t=sh

    ex) growthforecast-client delete 'http://{hostname}:{port}/list/{service_name}/{section_name}'
  LONGDESC
  option :graph_names,   :type => :array, :aliases => '-g'
  option :section_names, :type => :array, :aliases => '-s'
  def delete(url)
    section_names, graph_names = options[:section_names], options[:graph_names]

    base_uri, service_name, section_name, graph_name = split_url(url)
    @client = client(base_uri)

    graphs = @client.list_graph(service_name, section_name, graph_name)
    delete_graphs(graphs, graph_names, section_names)

    complexes = @client.list_complex(service_name, section_name, graph_name)
    delete_complexes(complexes, graph_names, section_names)
  end

  desc 'color <url>', 'change the color of graphs under url'
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

  desc 'create_complex <url>', 'create complex graphs under url'
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

  desc 'vrule <json> <api_url>', 'create a vertical line'
  long_desc <<-LONGDESC
    Create a vertical line

    ex) growthforecast-client vrule '{"dashes":"2,10"}' http://{hostname}:{port}/vrule/api[/{service_name}[/{section_name}[/{graph_name}]]]
  LONGDESC
  def vrule(json, url)
    base_uri, service_name, section_name, graph_name = split_url(url)
    @client = client(base_uri)
    puts @client.post_vrule(service_name, section_name, graph_name, JSON.parse(json))
  end

  desc 'bench <api_url>', 'benchmark the GrowthForecast'
  long_desc <<-LONGDESC
    Benchmark the GrowthForecast.

    ex) growthforecast-client bench http://{hostname}:{port} -n 100 -c 10
  LONGDESC
  option :requests, :type => :numeric,  :aliases => '-n', :default => 100
  option :concurrency, :type => :numeric,  :aliases => '-c', :default => 1
  def bench(url)
    requests, concurrency = options[:requests], options[:concurrency]
    require 'parallel'
    base_uri = split_url(url).first
    @client = client(base_uri)
    # generate unique paths of the same number with number of requests beforehand
    paths = []
    requests.times do |i|
      paths << [(i/100).to_s, (i/50).to_s, i.to_s]
    end
    # Take a benchmark in parallel
    start = Time.now
    Parallel.each_with_index(paths, :in_processes => concurrency) do |path, i|
      puts "Completed #{i} requests" if i % 1000 == 0 and i > 0
      @client.post_graph(path[0], path[1], path[2], { "number" => rand(1000) }) rescue nil
    end
    puts "Completed #{requests} requests"
    duration = (Time.now - start).to_f
    puts "Requests per second: #{requests / duration} [#/sec] (mean)"
    puts "Time per request:    #{duration / requests * 1000} [ms] (mean)"
  end

  no_tasks do
    def delete_graphs(graphs, graph_names = nil, section_names = nil)
      graphs.each do |graph|
        service_name, section_name, graph_name = graph['service_name'], graph['section_name'], graph['graph_name']
        next if section_names and !section_names.include?(section_name)
        next if graph_names   and !graph_names.include?(graph_name)

        puts "Delete #{service_name}/#{section_name}/#{graph_name}" unless @options[:silent]
        exec { @client.delete_graph(service_name, section_name, graph_name) }
      end
    end

    def delete_complexes(complexes, graph_names = nil, section_names = nil)
      complexes.each do |graph|
        service_name, section_name, graph_name = graph['service_name'], graph['section_name'], graph['graph_name']
        next if section_names and !section_names.include?(section_name)
        next if graph_names   and !graph_names.include?(graph_name)

        puts "Delete #{service_name}/#{section_name}/#{graph_name}" unless @options[:silent]
        exec { @client.delete_complex(service_name, section_name, graph_name) }
      end
    end

    def setup_colors(colors, graphs)
      graphs.each do |graph|
        service_name, section_name, graph_name = graph['service_name'], graph['section_name'], graph['graph_name']
        next unless color = colors[graph_name]

        params = { 'color'  => color }
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
        to_complex_params = { "service_name" => service_name, "section_name" => section_name, "graph_name" => to_complex, "sort" => 0 }

        puts "Setup #{service_name}/#{section_name}/#{to_complex} with #{from_graphs}" unless @options[:silent]
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

    def client(base_uri)
      GrowthForecast::Client.new(base_uri)
    end

    def split_url(url)
      uri = URI.parse(url)
      base_uri = "#{uri.scheme}://#{uri.host}:#{uri.port}"
      [base_uri] + split_path(uri.path)
    end

    def split_path(path)
      path = path.gsub(/.*list\/?/, '').gsub(/.*view_graph\/?/, '').gsub(/.*api\/?/, '')
      path.split('/').map {|p| CGI.unescape(p.gsub('%20', '+')) }
    end
  end
end

