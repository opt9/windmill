require 'spec_helper'

describe "osquery endpoint enroller" do
  before do
    @cg = ConfigurationGroup.create(name: "default")
    @empty = ConfigurationGroup.create(name: "empty")
    @config = @cg.configurations.create(name:"test", version:1, notes:"test", config_json: {test:"test"}.to_json)
    @endpoint = @cg.endpoints.create(node_key:SecureRandom.uuid)
  end
  
  it "records the original name of the configuration group in which it tried to enroll" do
    @endpoint = Enroller.enroll("test:default:valid_test", last_version: 1, last_ip: 1)
    expect(@endpoint.group_label).to eq("default")
  end
end
