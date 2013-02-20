# -*- encoding: utf-8 -*-
require 'growthforecast-client'

# Create a GrowthForecast Client, given he base URI of GrowthForecast
uri = 'http://localhost:5125'
client = GrowthForecast::Client.new(uri)

# configure colors of graphs whose names are as belows:
graph_colors = {
  '<1sec_count'  => '#1111cc',
  '<2sec_count'  => '#11cc11',
  '<3sec_count'  => '#cc7711',
  '<4sec_count'  => '#cccc11',
  '>=4sec_count' => '#cc1111',
}
# Apply for all services/sections
sections = client.list_section
sections.each do |service_name, sections|
  sections.each do |section_name|
    graph_colors.keys.each do |graph_name|
      data = {
        'color'  => graph_colors[graph_name],
        'unit'   => 'count',
        'sort'   => 1, # order to display, 19 is the top
        'adjust' => '/',
        'adjustval' => '1',
      }
      begin
        puts "Setup /#{service_name}/#{section_name}/#{graph_name}"
        client.edit_graph(service_name, section_name, graph_name, data)
      rescue GrowthForecast::NotFound => e
        puts "\tclass:#{e.class}\t#{e.message}"
      end
    end
  end
end
