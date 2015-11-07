require 'spec_helper'

describe 'Endpoint instance methods' do
  before do
    @cg = ConfigurationGroup.create(name: "default")
    @config = @cg.configurations.create(name:"test", version:1, notes:"test", config_json: {test:"test"}.to_json)
    @endpoint = @cg.endpoints.create(node_key:"test", group_label: "default")
    @endpoint.get_config
  end

  subject { @endpoint }
  it {should respond_to(:node_key)}
  it {should respond_to(:last_version)}
  it {should respond_to(:config_count)}
  it {should respond_to(:last_ip)}
  it {should respond_to(:created_at)}
  it {should respond_to(:updated_at)}
  it {should respond_to(:last_config_time)}
  it {should respond_to(:node_secret)}
  it {should respond_to(:identifier)}
  it {should respond_to(:group_label)}
  it {should respond_to(:assigned_config)}
  it {should respond_to(:last_config)}
  it {should respond_to(:configuration_group)}

  it "should know the configuration object to which it is assigned" do
    expect(@endpoint.assigned_config.id).to eq(@config.id)
  end

  it "should know the last configuration object which it received" do
    expect(@endpoint.last_config.id).to eq(@config.id)
  end

  it "should know the name of the configuration group it enrolled with" do
    expect(@endpoint.group_label).to eq("default")
  end

  it "should return configuration text" do
    expect(@endpoint.get_config).to eq({test:"test"}.to_json)
  end

  it "should return a configuration group" do
    expect(@endpoint.configuration_group.id).to eq(@cg.id)
  end

  it "should require a node_key" do
    expect(@endpoint.valid?).to be_truthy
    @endpoint.node_key = nil
    expect(@endpoint.valid?).to be_falsey
  end

  it "should require a configuration id" do
    expect(@endpoint.valid?).to be_truthy
    @endpoint.assigned_config_id = nil
    expect(@endpoint.valid?).to be_falsey
  end
end
