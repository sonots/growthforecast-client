# -*- encoding: utf-8 -*-
require 'thor'

class GrowthForecast::CLI < Thor
  desc 'delete_graph <url>', 'delete a graph or graphs under a url'
  long_desc <<-LONGDESC
    Delete a graph or graphs under a <url> where <url> is the one obtained from the view, e.g., 
    http://{hostname}:{port}/list/{service_name}/{section_name}?t=sh
    or
    http://{hostname}:{port}/view_graph/{service_name}/{section_name}/{graph_name}?t=sh
  LONGDESC
  def delete_graph(url)
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

  no_tasks do
    def e(str)
      CGI.escape(str).gsub('+', '%20') if str
    end

    def split_path(path)
      path = path.gsub(/.*list\//, '').gsub(/.*view_graph\//, '')
      path.split('/').map {|p| CGI.unescape(p.gsub('%20', '+')) }
    end

    def client(uri)
      GrowthForecast::Client.new("#{uri.scheme}://#{uri.host}:#{uri.port}")
    end
  end
end

