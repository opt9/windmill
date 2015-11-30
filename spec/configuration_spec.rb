require 'spec_helper'

describe "osquery configuration files" do
  before do
    @config = Configuration.create(name:"test", version:1, notes:"test", config_json: {test:"test"}.to_json)
    @endpoint = @config.assigned_endpoints.create(node_key:"test")
  end

  subject {@config}
  it { should respond_to :id }
  it { should respond_to :name }
  it { should respond_to :version }
  it { should respond_to :config_json }
  it { should respond_to :notes }
  it { should respond_to :configuration_group }
  it { should respond_to :assigned_endpoints }
  it { should respond_to :configured_endpoints }

  it "should require a name" do
    expect(@config.valid?).to be_truthy
    @config.name = nil
    expect(@config.valid?).to be_falsey
  end

  it "should require a version" do
    expect(@config.valid?).to be_truthy
    @config.version = nil
    expect(@config.valid?).to be_falsey
  end

  it "should require a config_json" do
    expect(@config.valid?).to be_truthy
    @config.config_json = nil
    expect(@config.valid?).to be_falsey
  end

  it "should require valid json in config_json" do
    expect(@config.valid?).to be_truthy
    @config.config_json = "not valid json"
    expect(@config.valid?).to be_falsey
  end

  it "should return a list of its assigned endpoints" do
    @endpoints = @config.assigned_endpoints
    expect(@endpoints.size).to eq(1)
  end

  it "should throw an error if you try to delete a configuration that is assigned to endpoints" do
    expect {@config.destroy}.to raise_error(RuntimeError)
  end
end
