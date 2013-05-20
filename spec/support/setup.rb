# -*- encoding: utf-8 -*-

shared_context "setup_growthforecast_client" do
  include_context "stub_list_graph" if ENV['MOCK'] == 'on'
  let(:graphs) { client.list_graph }
  let(:graph) { graphs.first }
  let(:from_graphs) do
    [
      graphs[0],
      graphs[1],
    ]
  end
  let(:to_complex) do
    {
      "service_name" => graphs.first["service_name"],
      "section_name" => graphs.first["section_name"],
      "graph_name"   => "complex graph test",
      "description"  => "complex graph test",
      "sort"         => 10
    }
  end

  include_context "stub_post_graph" if ENV['MOCK'] == 'on'
  include_context "stub_delete_graph" if ENV['MOCK'] == 'on'
  before(:all) {
    client.delete_graph("app name", "host name", "<1sec count") rescue nil
    client.delete_graph("app name", "host name", "<2sec count") rescue nil
    client.post_graph("app name", "host name", "<1sec count", { 'number' => 0 }) rescue nil
    client.post_graph("app name", "host name", "<2sec count", { 'number' => 0 }) rescue nil
  }
  after(:all) {
    client.delete_graph("app name", "host name", "<1sec count") rescue nil
    client.delete_graph("app name", "host name", "<2sec count") rescue nil
  }
end
