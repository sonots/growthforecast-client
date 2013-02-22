# -*- encoding: utf-8 -*-
# An example to create complex graphs

# require anyway
require 'growthforecast-client'

# Create a GrowthForecast Client, given he base URI of GrowthForecast
client = GrowthForecast::Client.new('http://localhost:5125')

# I gonna apply for all services/sections
sections = client.list_section
sections.each do |service_name, sections|
  sections.each do |section_name|
    # Make a complex graph from these graphs
    from_graphs= [
      {"service_name" => service_name, "section_name" => section_name, "graph_name" => "<1sec_count", "gmode" => 'gauge', "stack" => true, "type" => 'AREA'},
      {"service_name" => service_name, "section_name" => section_name, "graph_name" => "<2sec_count", "gmode" => 'gauge', "stack" => true, "type" => 'AREA'},
      {"service_name" => service_name, "section_name" => section_name, "graph_name" => "<3sec_count", "gmode" => 'gauge', "stack" => true, "type" => 'AREA'},
      {"service_name" => service_name, "section_name" => section_name, "graph_name" => "<4sec_count", "gmode" => 'gauge', "stack" => true, "type" => 'AREA'},
      {"service_name" => service_name, "section_name" => section_name, "graph_name" => ">=4sec_count", "gmode" => 'gauge', "stack" => true, "type" => 'AREA'},
    ]

    # The propety of a complex graph to create
    to_complex = {
      "service_name" => service_name,
      "section_name" => section_name,
      "graph_name"   => "response_time_count",
      "description"  => "response time count",
      "sort"         => 10,
    }

    # Create a complex graph!
    begin
      puts "Setup /#{service_name}/#{section_name}/#{to_complex['graph_name']}"
      client.create_complex(from_graphs, to_complex)
    rescue GrowthForecast::AlreadyExists => e
      puts "\tclass:#{e.class}\t#{e.message}"
    rescue GrowthForecast::NotFound => e
      puts "\tclass:#{e.class}\t#{e.message}"
    end
  end
end
