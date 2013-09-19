# -*- encoding: utf-8 -*-
require 'thor'

class GrowthForecast::CLI < Thor
  desc 'delete <url>', 'delete a graph or graphs under a url'
  long_desc <<-LONGDESC
    Delete a graph or graphs under a <url> where <url> is the one obtained from the GrowthForecast URI, e.g., 
    http://{hostname}:{port}/list/{service_name}/{section_name}?t=sh
    or
    http://{hostname}:{port}/view_graph/{service_name}/{section_name}/{graph_name}?t=sh

    ex) growthforecast-client delete 'http://{hostname}:{port}/list/{service_name}/{section_name}'
  LONGDESC
  def delete(url)
    uri = URI.parse(url)
    client = client(uri)
    service_name, section_name, graph_name = split_path(uri.path)
    graphs = client.list_graph(service_name, section_name, graph_name)
    graphs.each do |graph|
      begin
        client.delete_graph(graph['service_name'], graph['section_name'], graph['graph_name'])
        puts "Deleted #{e graph['service_name']}/#{e graph['section_name']}/#{e graph['graph_name']}"
      rescue => e
        puts "\tclass:#{e.class}\t#{e.message}"
      end
    end
    graphs = client.list_complex(service_name, section_name, graph_name)
    graphs.each do |graph|
      begin
        client.delete_complex(graph['service_name'], graph['section_name'], graph['graph_name'])
        puts "Deleted #{e graph['service_name']}/#{e graph['section_name']}/#{e graph['graph_name']}"
      rescue => e
        puts "\tclass:#{e.class}\t#{e.message}"
      end
    end
  end

  desc 'color', 'change the color of graphs'
  long_desc <<-LONGDESC
    Change the color of graphs

    ex) growthforecast-client color -c "2xx_count:#1111cc" "3xx_count:#11cc11" -u 'http://{hostname}:{port}/list/{service_name}/{section_name}'
  LONGDESC
  option :colors, :type => :hash,   :aliases => '-c', :required => true
  option :url,    :type => :string, :aliases => '-u', :required => true
  def color
    colors, url = options[:colors], options[:url]

    uri = URI.parse(url)
    client = client(uri)
    service_name, section_name, graph_name = split_path(uri.path)
    graphs = client.list_graph(service_name, section_name, graph_name)

    graphs.each do |graph|
      service_name, section_name, graph_name = graph['service_name'], graph['section_name'], graph['graph_name']
      next unless colors[graph_name]
      params = {
        'color'  => colors[graph_name],
        'unit'   => 'count',
        'sort'   => 1, # order to display, 19 is the top
        'adjust' => '/',
        'adjustval' => '1',
      }
      begin
        puts "Setup #{service_name}/#{section_name}/#{graph_name} with #{colors[graph_name]}"
        client.edit_graph(service_name, section_name, graph_name, params)
      rescue GrowthForecast::NotFound => e
        $stderr.puts "\tclass:#{e.class}\t#{e.message}"
      end
    end
  end

  desc 'create_complex', 'create complex graphs'
  long_desc <<-LONGDESC
    Create complex graphs under a <url>

    ex) growthforecast-client create_complex -f 2xx_count 3xx_count -t status_count -u 'http://{hostname}:{port}/list/{service_name}'
  LONGDESC
  option :from_graphs, :type => :array,  :aliases => '-f', :required => true
  option :to_complex,  :type => :string, :aliases => '-t', :required => true
  option :url,  :type => :string, :aliases => '-u', :required => true
  def create_complex
    from_graphs, to_complex, url = options[:from_graphs], options[:to_complex], options[:url]

    uri = URI.parse(url)
    client = client(uri)
    service_name, section_name, graph_name = split_path(uri.path)
    sections = client.list_section(service_name, section_name, graph_name)

    sections.each do |service_name, sections|
      sections.each do |section_name|
        base = { "service_name" => service_name, "section_name" => section_name, "gmode" => 'gauge', "stack" => true, "type" => 'AREA' }
        from_graphs_params = from_graphs.map {|graph_name| base.merge('graph_name' => graph_name) }
        to_complex_params = { "service_name" => service_name, "section_name" => section_name, "graph_name" => to_complex, "sort" => 1 }
        begin
          puts "Setup /#{service_name}/#{section_name}/#{to_complex} with #{from_graphs}"
          client.create_complex(from_graphs_params, to_complex_params)
        rescue GrowthForecast::AlreadyExists => e
          $stderr.puts "\tclass:#{e.class}\t#{e.message}"
        rescue GrowthForecast::NotFound => e
          $stderr.puts "\tclass:#{e.class}\t#{e.message}"
        end
      end
    end
  end

  no_tasks do
    def e(str)
      CGI.escape(str).gsub('+', '%20') if str
    end

    def split_path(path)
      path = path.gsub(/.*list\/?/, '').gsub(/.*view_graph\/?/, '')
      path.split('/').map {|p| CGI.unescape(p.gsub('%20', '+')) }
    end

    def client(uri)
      GrowthForecast::Client.new("#{uri.scheme}://#{uri.host}:#{uri.port}")
    end
  end
end

