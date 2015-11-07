require 'spec_helper'

describe "osquery configuration groups" do
  before do
    @cg = ConfigurationGroup.create(name: "test")
    @cg2 = ConfigurationGroup.new(name: "test2")
    @config = @cg.configurations.create(name: "test_config", version: 1, config_json: {test: "test"}.to_json)
    @config2 = @cg.configurations.create(name: "test_config2", version:1, config_json: {test: "test2"}.to_json)
    @endpoint = @cg.endpoints.create(node_key:"test")
  end

  subject {@cg}
  it { should respond_to :id }
  it { should respond_to :name }
  it { should respond_to :configurations }
  it { should respond_to :endpoints }
  it { should respond_to :default_config }
  it { should respond_to :default_config= }

  it "should require a name" do
    expect(@cg2.valid?).to be_truthy
    @cg2.name = nil
    expect(@cg2.valid?).to be_falsey
  end

  it "should return a collection of endpoints" do
    expect(@cg.endpoints.count).to be > 0
  end

  it "should return a collection of configurations" do
    @configs = @cg.configurations.all
    expect(@configs.length).to be > 0
  end

  it "should return the first configuration if no default_config is set" do
    expect(@cg.default_config).to eq(@config)
  end

  it "should allow you to set a different default_config" do
    @cg.default_config = @config
    expect(@cg.default_config).to eq(@config)
  end

  it "should allow you to set a configuration as the canary deploy" do
    @cg.canary_config = @config2
    expect(@cg.canary_config).to eq(@config2)
  end

  it "should know if a canary deployment is in progress" do
    expect(@cg.canary_in_progress?).to be_falsey
    @cg.canary_config = @config2
    expect(@cg.canary_in_progress?).to be_truthy
  end

  it "should not allow you to set a canary deployment if one is in progress" do
    @cg.canary_config = @config2
    expect {@cg.canary_config = @config }.to raise_error(RuntimeError)
    expect(@cg.canary_config).to eq(@config2)
  end

  it "should cancel a canary deploy and set all endpoints back to default" do
    # Without specifying, @config is the default configuration for @cg
    # We will start a canary and assign @endpoint the new config
    # then cancel the canary and check if @endpoint has been reassigned
    @cg.canary_config = @config2
    @cg.assign_config_percent(@config2, 100)
    @cg.cancel_canary
    expect(@cg.canary_in_progress?).to be_falsey
    expect(@endpoint.assigned_config).to eq(@config)
  end

  it "should throw an error if you try to cancel a canary when one isn't in progress" do
    @cg.canary_config = @config2
    expect {@cg.canary_config = @config}.to raise_error(RuntimeError)
    expect(@cg.canary_in_progress?).to be_truthy
  end

  it "should promote a canary to default and set all endpoints to the new config" do
    @cg.canary_config = @config2
    @cg.promote_canary
    @endpoint.reload
    expect(@cg.canary_in_progress?).to be_falsey
    expect(@cg.default_config).to eq(@config2)
    expect(@endpoint.assigned_config).to eq(@config2)
  end

  it "should throw an error if you try to promote a canary when one isn't in progress" do
    expect {@cg.promote_canary}.to raise_error(RuntimeError)
  end

  it "should throw an error if you try to delete a configuration group that has endpoints" do
    expect {@cg.destroy}.to raise_error(RuntimeError)
  end
end
