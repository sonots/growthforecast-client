# -*- encoding: utf-8 -*-
# An example to edit properties of graphs such as color, unit. 

# require anyway
require 'growthforecast-client'

# Create a GrowthForecast Client, given he base URI of GrowthForecast
client = GrowthForecast::Client.new('http://localhost:5125')
client.debug_dev = STDOUT # debug print the http requests and responses

# configure colors of graphs whose names are as belows:
graph_colors = {
  '<1sec_count'  => '#1111cc',
  '<2sec_count'  => '#11cc11',
  '<3sec_count'  => '#cc7711',
  '<4sec_count'  => '#cccc11',
  '>=4sec_count' => '#cc1111',
}
# I gonna apply for all services/sections
sections = client.list_section
sections.each do |service_name, sections|
  sections.each do |section_name|
    graph_colors.keys.each do |graph_name|
      # Graph properties to overwrite
      params = {
        'color'  => graph_colors[graph_name],
        'unit'   => 'count',
        'sort'   => 1, # order to display, 19 is the top
        'adjust' => '/',
        'adjustval' => '1',
      }
      # Edit a graph
      begin
        puts "Setup /#{service_name}/#{section_name}/#{graph_name}"
        client.edit_graph(service_name, section_name, graph_name, params)
      rescue GrowthForecast::NotFound => e
        puts "\tclass:#{e.class}\t#{e.message}"
      end
    end
  end
end
