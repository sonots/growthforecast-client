# -*- encoding: utf-8 -*-
require 'growthforecast-client'

# Create a GrowthForecast Client, given he base URI of GrowthForecast
uri = 'http://localhost:5125'
client = GrowthForecast::Client.new(uri)

# Apply for all services/sections
sections = client.list_section
sections.each do |service_name, sections|
  sections.each do |section_name|
    # Make a complex graph from these graphs
    from_graphs= [
      {:path => "#{service_name}/#{section_name}/<1sec_count", :gmode => 'gauge', :stack => true, :type => 'AREA'},
      {:path => "#{service_name}/#{section_name}/<2sec_count", :gmode => 'gauge', :stack => true, :type => 'AREA'},
      {:path => "#{service_name}/#{section_name}/<3sec_count", :gmode => 'gauge', :stack => true, :type => 'AREA'},
      {:path => "#{service_name}/#{section_name}/<4sec_count", :gmode => 'gauge', :stack => true, :type => 'AREA'},
      {:path => "#{service_name}/#{section_name}/>=4sec_count", :gmode => 'gauge', :stack => true, :type => 'AREA'},
    ]

    # The propety of a complex graph to create, e.g., path
    to_complex = {
      :path         => "#{service_name}/#{section_name}/response_count",
      :description  => 'response time count',
      :sort         => 10,
    }

    begin
      puts "Setup #{to_complex[:path]}"
      client.create_complex(from_graphs, to_complex)
    rescue GrowthForecast::AlreadyExists => e
      puts "\tclass:#{e.class}\t#{e.message}"
    rescue GrowthForecast::NotFound => e
      puts "\tclass:#{e.class}\t#{e.message}"
    end
  end
end
