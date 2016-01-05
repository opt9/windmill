require 'spec_helper'

describe "osquery missing configuration object" do
  before do
    @config = MissingConfiguration.new
  end

  subject {@config}
  it { should respond_to :id }
  it "should have a name" do
    expect(@config.name).to eq("Missing Configuration")
  end
end
