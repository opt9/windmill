require 'spec_helper'

describe "osquery api keys" do
  before do
    @apiread = APIKey.create notes: "test", perms: "read"
  end

  it "should auto-generate a key when created" do
    expect(@apiread.save).to be_truthy
    @apiread.reload
    expect(@apiread.valid?).to be_truthy
  end

  it "should require a key" do
    @apikey = APIKey.new
    @apikey.key = ""
    expect(@apikey.valid?).to be_falsey
  end

  it "should require a permission" do
    @apikey = APIKey.new
    @apikey.perms = ""
    expect(@apikey.valid?).to be_falsey
  end
end
