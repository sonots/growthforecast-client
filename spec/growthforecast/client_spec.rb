require 'spec_helper'

describe GrowthForecast::Client do
  include_context "setup_growthforecast_client"
  id_keys    = %w[id service_name section_name graph_name]
  graph_keys = %w[number llimit mode stype adjustval gmode color created_at ulimit description
                  sulimit unit sort updated_at adjust type sllimit meta md5]
  complex_keys = %w[number complex created_at service_name section_name id graph_name data sumup
                    description sort updated_at]

  context "#list_graph" do
    include_context "stub_list_graph" if ENV['MOCK'] == 'on'
    subject { graphs }
    its(:size) { should > 0 }
    id_keys.each {|key| its(:first) { should have_key(key) } }
  end

  context "#list_section" do
    include_context "stub_list_graph" if ENV['MOCK'] == 'on'
    subject { client.list_section }
    its(:size) { should > 0 }
    its(:class) { should == Hash }
    it { subject.each {|service_name, sections| sections.size.should > 0 } }
  end

  context "#list_service" do
    include_context "stub_list_graph" if ENV['MOCK'] == 'on'
    subject { client.list_service }
    its(:size) { should > 0 }
    its(:class) { should == Array }
  end

  context "#get_graph" do
    include_context "stub_get_graph" if ENV['MOCK'] == 'on'
    subject { client.get_graph(graph["service_name"], graph["section_name"], graph["graph_name"]) }
    id_keys.each {|key| it { subject[key].should == graph[key] } }
    graph_keys.each {|key| it { subject.should have_key(key) } }
  end

  context "#get_graph_by_id" do
    include_context "stub_get_graph_by_id" if ENV['MOCK'] == 'on'
    subject { client.get_graph_by_id(graph["id"]) }
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
    subject { client.post_graph(graph["service_name"], graph["section_name"], graph["graph_name"], params) }
    it { subject["error"].should == 0 }
    params.keys.each {|key| it { subject["data"][key].should == params[key] } }
  end

  context "#delete_graph" do
    include_context "stub_post_graph" if ENV['MOCK'] == 'on'
    include_context "stub_delete_graph" if ENV['MOCK'] == 'on'
    before { client.post_graph(graph['service_name'], graph['section_name'], graph['graph_name'], { 'number' => 0 }) }
    subject { client.delete_graph(graph['service_name'], graph['section_name'], graph['graph_name']) }
    it { subject["error"].should == 0 }
  end

  context "#delete_graph_by_id" do
    include_context "stub_post_graph" if ENV['MOCK'] == 'on'
    let(:graph) {
      {
        "service_name" => "app name",
        "section_name" => "host name",
        "graph_name"   => "<1sec count",
      }
    }
    let(:id) do
      ret = client.post_graph(graph['service_name'], graph['section_name'], graph['graph_name'], { 'number' => 0 })
      ret["data"]["id"]
    end
    include_context "stub_delete_graph_by_id" if ENV['MOCK'] == 'on'
    subject { client.delete_graph_by_id(id) }
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
      before do
        @before = client.get_graph(graph["service_name"], graph["section_name"], graph["graph_name"])
        @response = client.edit_graph(graph["service_name"], graph["section_name"], graph["graph_name"], params)
        @after = client.get_graph(graph["service_name"], graph["section_name"], graph["graph_name"])
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
      before do
        @before = client.get_graph(graph["service_name"], graph["section_name"], graph["graph_name"])
        @response = client.edit_graph(graph["service_name"], graph["section_name"], graph["graph_name"], params)
        @after = client.get_graph(graph["service_name"], graph["section_name"], graph["graph_name"])
      end
      params.keys.each {|key| it { @after[key].should == @before[key] } }
    end
  end

  context "#create_complex" do
    include_context "stub_create_complex" if ENV['MOCK'] == 'on'
    include_context "stub_delete_complex" if ENV['MOCK'] == 'on'
    subject { client.create_complex(from_graphs, to_complex) }
    it { subject["error"].should == 0 }
    after { client.delete_complex(to_complex["service_name"], to_complex["section_name"], to_complex["graph_name"]) }
  end

  context "#get_complex" do
    include_context "stub_create_complex" if ENV['MOCK'] == 'on'
    include_context "stub_get_complex" if ENV['MOCK'] == 'on'
    include_context "stub_delete_complex" if ENV['MOCK'] == 'on'
    before { client.create_complex(from_graphs, to_complex) }
    subject { client.get_complex(to_complex["service_name"], to_complex["section_name"], to_complex["graph_name"]) }
    complex_keys.each {|key| it { subject.should have_key(key) } }
    after { client.delete_complex(to_complex["service_name"], to_complex["section_name"], to_complex["graph_name"]) }
  end

  context "#get_complex_by_id" do
    include_context "stub_create_complex" if ENV['MOCK'] == 'on'
    include_context "stub_get_complex" if ENV['MOCK'] == 'on'
    before { client.create_complex(from_graphs, to_complex) }
    let(:id) { client.get_complex(to_complex["service_name"], to_complex["section_name"], to_complex["graph_name"])["id"] }
    include_context "stub_get_complex_by_id" if ENV['MOCK'] == 'on'
    include_context "stub_delete_complex_by_id" if ENV['MOCK'] == 'on'
    subject { client.get_complex_by_id(id) }
    complex_keys.each {|key| it { subject.should have_key(key) } }
    after { client.delete_complex_by_id(id) }
  end

  describe 'http://blog.64p.org/?page=1366971426' do
    before { @client ||= client }

    context "#last_response" do
      include_context "stub_list_graph" if ENV['MOCK'] == 'on'
      before { @client.list_graph }
      subject { @client.last_response }
      it { should be_kind_of Net::HTTPResponse }
    end

    context "#last_request_uri" do
      include_context "stub_list_graph" if ENV['MOCK'] == 'on'
      before { @client.list_graph }
      subject { @client.last_request_uri }
      it { should == "http://localhost:5125/json/list/graph" }
    end
  end
end

