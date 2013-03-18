require 'spec_helper'

describe CLI::GrowthforecastClient do
  include_context "setup_growthforecast_client"
  before(:all) { @cli = CLI::GrowthforecastClient.new }

  context "#split_path" do
    context 'list service url' do
      before { @url = 'http://localhost/list/service_name?t=sh' }
      before { @service_name, @section_name, @graph_name = @cli.split_path(URI.parse(@url).path) }
      it { @service_name.should == 'service_name' }
      it { @section_name.should be_nil }
      it { @graph_name.should be_nil }
    end

    context 'list section url' do
      before { @url = 'http://localhost/list/service_name/section_name?t=sh' }
      before { @service_name, @section_name, @graph_name = @cli.split_path(URI.parse(@url).path) }
      it { @service_name.should == 'service_name' }
      it { @section_name.should == 'section_name' }
      it { @graph_name.should be_nil }
    end

    context 'view_graph url' do
      before { @url = 'http://localhost/view_graph/service_name/section_name/graph_name?t=sh' }
      before { @service_name, @section_name, @graph_name = @cli.split_path(URI.parse(@url).path) }
      it { @service_name.should == 'service_name' }
      it { @section_name.should == 'section_name' }
      it { @graph_name.should == 'graph_name' }
    end
  end

  context "delete_graph" do
    pending
  end
end

