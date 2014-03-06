# -*- encoding: utf-8 -*-

shared_context "stub_list_graph" do
  def list_graph_example
    [
      {"service_name"=>"app name",
       "section_name"=>"host name",
       "graph_name"=>"<1sec count",
       "id"=>1},
      {"service_name"=>"app name",
       "section_name"=>"host name",
       "graph_name"=>"<2sec count",
       "id"=>2},
    ]
  end

  proc = Proc.new do
    stub_request(:get, "#{base_uri}/json/list/graph").to_return(:status => 200, :body => list_graph_example.to_json)
  end
  before(:each, &proc)
end

shared_context "stub_get_graph" do
  def graph_example
    {
      "number"=>0,
      "llimit"=>-1000000000,
      "mode"=>"gauge",
      "stype"=>"AREA",
      "adjustval"=>"1",
      "meta"=>"",
      "service_name"=>"app name",
      "gmode"=>"gauge",
      "color"=>"#cc6633",
      "created_at"=>"2013/02/02 00:41:11",
      "section_name"=>"host name",
      "ulimit"=>1000000000,
      "id"=>1,
      "graph_name"=>"<1sec count",
      "description"=>"",
      "sulimit"=>100000,
      "unit"=>"",
      "sort"=>0,
      "updated_at"=>"2013/02/02 02:32:10",
      "adjust"=>"*",
      "type"=>"AREA",
      "sllimit"=>-100000,
      "md5"=>"3c59dc048e8850243be8079a5c74d079"
    }
  end

  proc = Proc.new do
    stub_request(:get, "#{base_uri}/api/#{e graph['service_name']}/#{e graph['section_name']}/#{e graph['graph_name']}").
    to_return(:status => 200, :body => graph_example.to_json)
  end
  before(:each, &proc)
end

shared_context "stub_get_graph_by_id" do
  # /json/graph/:id does not return `meta` and `md5`
  def graph_example
    {
      "number"=>0,
      "llimit"=>-1000000000,
      "mode"=>"gauge",
      "stype"=>"AREA",
      "adjustval"=>"1",
      # "meta"=>"",
      "service_name"=>"app name",
      "gmode"=>"gauge",
      "color"=>"#cc6633",
      "created_at"=>"2013/02/02 00:41:11",
      "section_name"=>"host name",
      "ulimit"=>1000000000,
      "id"=>1,
      "graph_name"=>"<1sec count",
      "description"=>"",
      "sulimit"=>100000,
      "unit"=>"",
      "sort"=>0,
      "updated_at"=>"2013/02/02 02:32:10",
      "adjust"=>"*",
      "type"=>"AREA",
      "sllimit"=>-100000,
      # "md5"=>"3c59dc048e8850243be8079a5c74d079"
    }
  end

  proc = Proc.new do
    stub_request(:get, "#{base_uri}/json/graph/#{graph['id']}").
    to_return(:status => 200, :body => graph_example.to_json)
  end
  before(:each, &proc)
end

shared_context "stub_post_graph" do
  include_context "stub_get_graph"
  before do
    stub_request(:post, "#{base_uri}/api/#{e graph['service_name']}/#{e graph['section_name']}/#{e graph['graph_name']}").
    to_return(:status => 200, :body => { "error" => 0, "data" => graph_example }.to_json)
  end
end

shared_context "stub_delete_graph" do
  proc = Proc.new do
    stub_request(:post, "#{base_uri}/delete/#{e graph['service_name']}/#{e graph['section_name']}/#{e graph['graph_name']}").
    to_return(:status => 200, :body => { "error" => 0 }.to_json)
  end
  before(:each, &proc)
end

shared_context "stub_delete_graph_by_id" do
  proc = Proc.new do
    stub_request(:post, "#{base_uri}/json/delete/graph/#{id}").
    to_return(:status => 200, :body => { "error" => 0 }.to_json)
  end
  before(:each, &proc)
end

shared_context "stub_edit_graph" do
  include_context "stub_get_graph"

  proc = Proc.new do
    stub_request(:post, "#{base_uri}/json/edit/graph/#{graph['id']}").
    to_return(:status => 200, :body => { "error" => 0 }.to_json)
  end
  before(:each, &proc)
end

shared_context "stub_list_complex" do
  def list_complex_example
    [
      {"service_name"=>"app name",
       "section_name"=>"host name",
       "graph_name"=>"complex graph test",
       "id"=>1},
    ]
  end

  proc = Proc.new do
    stub_request(:get, "#{base_uri}/json/list/complex").
    to_return(:status => 200, :body => list_complex_example.to_json)
  end
  before(:each, &proc)
end

shared_context "stub_get_complex" do
  def complex_example
    {"number"=>0,
     "complex"=>true,
     "created_at"=>"2013/05/20 15:08:28",
     "service_name"=>"app name",
     "section_name"=>"host name",
     "id"=>1,
     "graph_name"=>"complex graph test",
     "data"=>
    [{"gmode"=>"gauge", "stack"=>false, "type"=>"AREA", "graph_id"=>218},
     {"gmode"=>"gauge", "stack"=>true, "type"=>"AREA", "graph_id"=>217}],
    "sumup"=>false,
    "description"=>"complex graph test",
    "sort"=>10,
    "updated_at"=>"2013/05/20 15:08:28"}
  end

  proc = Proc.new do
    stub_request(:get, "#{base_uri}/json/complex/#{e to_complex['service_name']}/#{e to_complex['section_name']}/#{e to_complex['graph_name']}").
    to_return(:status => 200, :body => complex_example.to_json)
  end
  before(:each, &proc)
end

shared_context "stub_get_complex_by_id" do
  def complex_example
    {"number"=>0,
     "complex"=>true,
     "created_at"=>"2013/05/20 15:08:28",
     "service_name"=>"app name",
     "section_name"=>"host name",
     "id"=>1,
     "graph_name"=>"complex graph test",
     "data"=>
    [{"gmode"=>"gauge", "stack"=>false, "type"=>"AREA", "graph_id"=>218},
     {"gmode"=>"gauge", "stack"=>true, "type"=>"AREA", "graph_id"=>217}],
    "sumup"=>false,
    "description"=>"complex graph test",
    "sort"=>10,
    "updated_at"=>"2013/05/20 15:08:28"}
  end

  proc = Proc.new do
    stub_request(:get, "#{base_uri}/json/complex/#{id}").
    to_return(:status => 200, :body => complex_example.to_json)
  end
  before(:each, &proc)
end

shared_context "stub_delete_complex" do
  proc = Proc.new do
    stub_request(:post, "#{base_uri}/json/delete/complex/#{e to_complex['service_name']}/#{e to_complex['section_name']}/#{e to_complex['graph_name']}").
    to_return(:status => 200, :body => { "error" => 0 }.to_json)
  end
  before(:each, &proc)
end

shared_context "stub_delete_complex_by_id" do
  proc = Proc.new do
    stub_request(:post, "#{base_uri}/delete_complex/#{id}").
    to_return(:status => 200, :body => { "error" => 0 }.to_json)
  end
  before(:each, &proc)
end

shared_context "stub_create_complex" do
  include_context "stub_list_complex"

  proc = Proc.new do
    list_graph_example.each do |graph|
      stub_request(:get, "#{base_uri}/api/#{e graph['service_name']}/#{e graph['section_name']}/#{e graph['graph_name']}").
      to_return(:status => 200, :body => graph.to_json)
    end

    stub_request(:post, "#{base_uri}/json/create/complex").
    to_return(:status => 200, :body => { "error" => 0 }.to_json)
  end
  before(:each, &proc)
end

shared_context "stub_get_notfound_graph" do
  def notfound_graph
    {
      'service_name' => 'not found',
      'section_name' => 'not found',
      'graph_name'   => 'not found',
    }
  end
  proc = Proc.new do
    stub_request(:get, "#{base_uri}/api/#{e notfound_graph['service_name']}/#{e notfound_graph['section_name']}/#{e notfound_graph['graph_name']}").
    to_return(:status => 404, :body => '<html><body><strong>404</strong> Not Found</body></html>')
  end
  before(:each, &proc)
end
