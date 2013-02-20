require 'spec_helper'

describe GrowthForecast::Client do
  id_keys    = %w[id service_name section_name graph_name]
  graph_keys = %w[number llimit mode stype adjustval gmode color created_at ulimit description
                  sulimit unit sort updated_at adjust type sllimit meta md5]

  before(:all) { @client = GrowthForecast::Client.new('http://localhost:5125') }
  include_context "stub_list_graph" if ENV['MOCK'] == 'on'
  include_context "stub_post_graph" if ENV['MOCK'] == 'on'
  include_context "stub_delete_graph" if ENV['MOCK'] == 'on'
  before(:all) {
    @client.delete_graph("app_name", "hostname", "<1sec_count") rescue nil
    @client.delete_graph("app_name", "hostname", "<2sec_count") rescue nil
    @client.post_graph("app_name", "hostname", "<1sec_count", { 'number' => 0 }) rescue nil
    @client.post_graph("app_name", "hostname", "<2sec_count", { 'number' => 0 }) rescue nil
  }
  after(:all) {
    @client.delete_graph("app_name", "hostname", "<1sec_count") rescue nil
    @client.delete_graph("app_name", "hostname", "<2sec_count") rescue nil
  }
  include_context "stub_list_graph" if ENV['MOCK'] == 'on'
  let(:graphs) { @client.list_graph }
  let(:graph) { graphs.first }

  context "#list_graph" do
    include_context "stub_list_graph" if ENV['MOCK'] == 'on'
    subject { graphs }
    its(:size) { should > 0 }
    id_keys.each {|key| its(:first) { should have_key(key) } }
  end

  context "#get_graph" do
    include_context "stub_get_graph" if ENV['MOCK'] == 'on'
    subject { @client.get_graph(graph["service_name"], graph["section_name"], graph["graph_name"]) }
    id_keys.each {|key| it { subject[key].should == graph[key] } }
    graph_keys.each {|key| it { subject.should have_key(key) } }
  end

  context "#get_graph_by_id" do
    include_context "stub_get_graph_by_id" if ENV['MOCK'] == 'on'
    subject { @client.get_graph_by_id(graph["id"]) }
    id_keys.each {|key| it { subject[key].should == graph[key] } }
    # this is the behavior of GrowthForecast API
    (graph_keys - %w[meta md5]).each {|key| it { subject.should have_key(key) } }
  end

  context "#post_graph" do
    include_context "stub_post_graph" if ENV['MOCK'] == 'on'
    include_context "stub_get_graph" if ENV['MOCK'] == 'on'
    params = {
      'number' => 0,
    }
    subject { @client.post_graph(graph["service_name"], graph["section_name"], graph["graph_name"], params) }
    it { subject["error"].should == 0 }
    params.keys.each {|key| it { subject["data"][key].should == params[key] } }
  end

  context "#delete_graph" do
    include_context "stub_post_graph" if ENV['MOCK'] == 'on'
    include_context "stub_delete_graph" if ENV['MOCK'] == 'on'
    let(:graph) {
      {
        "service_name" => "app_name",
        "section_name" => "hostname",
        "graph_name"   => "<1sec_count",
      }
    }
    before  { @client.post_graph(graph['service_name'], graph['section_name'], graph['graph_name'], { 'number' => 0 }) }
    subject { @client.delete_graph(graph['service_name'], graph['section_name'], graph['graph_name']) }
    it { subject["error"].should == 0 }
  end

  context "#edit_graph" do
    context "normal" do
      include_context "stub_edit_graph" if ENV['MOCK'] == 'on'
      params = {
        'sort' => 19,
        'adjust' => '/',
        'adjustval' => '1000000',
        'unit' => 'sec',
        'color'  => "#000000"
      }
      before(:all) do
        @before = @client.get_graph(graph["service_name"], graph["section_name"], graph["graph_name"])
        @response = @client.edit_graph(graph["service_name"], graph["section_name"], graph["graph_name"], params)
        @after = @client.get_graph(graph["service_name"], graph["section_name"], graph["graph_name"])
      end
      it { @response["error"].should == 0 }
      # @todo: how to stub @after?
      unless ENV['MOCK'] == 'on'
        (id_keys + graph_keys - params.keys - %w[meta md5]).each {|key| it { @after[key].should == @before[key] } }
        params.keys.each {|key| it { @after[key].should == params[key] } }
      end
    end

    # this is the behavior of GrowthForecast API
    context "number and mode does not affect" do
      include_context "stub_edit_graph" if ENV['MOCK'] == 'on'
      params = {
        'number' => 0,
        'mode'   => 'count',
      }
      before(:all) do
        @before = @client.get_graph(graph["service_name"], graph["section_name"], graph["graph_name"])
        @response = @client.edit_graph(graph["service_name"], graph["section_name"], graph["graph_name"], params)
        @after = @client.get_graph(graph["service_name"], graph["section_name"], graph["graph_name"])
      end
      params.keys.each {|key| it { @after[key].should == @before[key] } }
    end
  end

  context "#create_complex" do
    include_context "stub_create_complex" if ENV['MOCK'] == 'on'
    include_context "stub_delete_complex" if ENV['MOCK'] == 'on'
    context "normal" do
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
          "graph_name"   => "complex_graph_test",
          "description"  => "complex graph test",
          "sort"         => 10
        }
      end
      subject { @client.create_complex(from_graphs, to_complex) }
      it { subject["error"].should == 0 }
      after { @client.delete_complex(to_complex["service_name"], to_complex["section_name"], to_complex["graph_name"]) }
    end
  end
end

