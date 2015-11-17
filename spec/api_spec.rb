require 'spec_helper'


describe 'The osquery TLS api' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  before do
    @cg = ConfigurationGroup.create(name: "default")
    @empty = ConfigurationGroup.create(name: "empty")
    @config = @cg.configurations.create(name:"test", version:1, notes:"test", config_json: {test:"test"}.to_json)
    @endpoint = @cg.endpoints.create(node_key:SecureRandom.uuid)
  end

  valid_node_key = ""

  it "sets a new client's config_count to zero" do
    post '/api/enroll', {enroll_secret: "valid_test"}
    expect(last_response).to be_ok
    expect(last_response.content_type).to eq("application/json")
    json = JSON.parse(last_response.body)
    client = Endpoint.find_by node_key: json['node_key']
    expect(client.config_count).to eq(0)
  end

  it "sets a new clients last_config_time to nil" do
    post '/api/enroll', {enroll_secret: "valid_test"}
    expect(last_response).to be_ok
    expect(last_response.content_type).to eq("application/json")
    json = JSON.parse(last_response.body)
    client = Endpoint.find_by node_key: json['node_key']
    expect(client.last_config_time).to eq(nil)
  end

  it "counts how many times a client has pulled its config" do
    client = Endpoint.last
    config_count = client.config_count
    post '/api/config', node_key: client.node_key
    expect(last_response).to be_ok
    expect(last_response.content_type).to eq("application/json")
    client.reload
    expect(client.config_count).to eq(config_count + 1)
  end

  it "updates the timestamp in last_config_time when a client pulls its config" do
    @client = Endpoint.last
    config_time = @client.last_config_time || Time.now
    post '/api/config', node_key: @client.node_key
    expect(last_response).to be_ok
    expect(last_response.content_type).to eq("application/json")
    @client.reload
    expect(@client.last_config_time).to be > config_time
  end

  it "returns a status" do
    get '/api/status'
    expect(last_response).to be_ok
    expect(last_response.content_type).to eq("application/json")
    json = JSON.parse(last_response.body)
    expect(json["status"]).to eq("running")
    expect(json).to have_key("timestamp")
  end

  it "enrolls a node with a valid enroll secret" do
    pre_enroll_endpoint_count = Endpoint.count
    post '/api/enroll', {enroll_secret: "valid_test"}
    expect(last_response).to be_ok
    expect(last_response.content_type).to eq("application/json")
    json = JSON.parse(last_response.body)
    expect(json).to have_key("node_key")
    valid_node_key = json["node_key"]
    expect(Endpoint.count).to eq(pre_enroll_endpoint_count + 1)
  end

  it "rejects a node with an invalid enroll secret" do
    post '/api/enroll', enroll_secret: "invalid_test"
    expect(last_response).to be_ok
    expect(last_response.content_type).to eq("application/json")
    json = JSON.parse(last_response.body)
    expect(json).to have_key("node_invalid")
    expect(json["node_invalid"]).to eq(true)
  end

  it "records ConfigurationGroup and identifier when a node enrolls with a valid enroll secret" do
    post '/api/enroll', {enroll_secret: "hostname:default:valid_test"}
    expect(last_response).to be_ok
    expect(last_response.content_type).to eq("application/json")
    json = JSON.parse(last_response.body)
    expect(json).to have_key("node_key")
    valid_node_key = json["node_key"]
    @endpoint = GuaranteedEndpoint.find_by node_key: valid_node_key
    expect(@endpoint.identifier).to eq("hostname")
    expect(@endpoint.configuration_group_id).to eq(ConfigurationGroup.find_by(name:"default").id)
  end

  it "records just the ConfigurationGroup when a node enrolls with a valid enroll secret" do
    post '/api/enroll', {enroll_secret: "default:valid_test"}
    expect(last_response).to be_ok
    expect(last_response.content_type).to eq("application/json")
    json = JSON.parse(last_response.body)
    expect(json).to have_key("node_key")
    valid_node_key = json["node_key"]
    @endpoint = GuaranteedEndpoint.find_by node_key: valid_node_key
    expect(@endpoint.identifier).to eq(nil)
    expect(@endpoint.configuration_group_id).to eq(ConfigurationGroup.find_by(name:"default").id)
  end

  it "enrolls an endpoint into the default ConfigurationGroup when an invalid group name is supplied" do
    post '/api/enroll', {enroll_secret: "hostname:invalid:valid_test"}
    expect(last_response).to be_ok
    expect(last_response.content_type).to eq("application/json")
    json = JSON.parse(last_response.body)
    expect(json).to have_key("node_key")
    valid_node_key = json["node_key"]
    @endpoint = GuaranteedEndpoint.find_by node_key: valid_node_key
    expect(@endpoint.identifier).to eq("hostname")
    expect(@endpoint.configuration_group_id).to eq(GuaranteedConfigurationGroup.find_by(name: "default").id)
  end

  it "enrolls an endpoint into the default ConfigurationGroup when a valid group name is supplied but the group has no configurations" do
    post '/api/enroll', {enroll_secret: "empty-test:empty:valid_test"}
    expect(last_response).to be_ok
    expect(last_response.content_type).to eq("application/json")
    json = JSON.parse(last_response.body)
    expect(json).to have_key("node_key")
    valid_node_key = json["node_key"]
    @endpoint = GuaranteedEndpoint.find_by node_key: valid_node_key
    expect(@endpoint.identifier).to eq("empty-test")
    expect(@endpoint.configuration_group_id).to eq(GuaranteedConfigurationGroup.find_by(name: "default").id)
  end

  it "returns a configuration with a valid node secret" do
    @endpoint = Endpoint.last
    post '/api/config', node_key: @endpoint.node_key
    expect(last_response).to be_ok
    expect(last_response.content_type).to eq("application/json")
    expect(last_response.body).to match(@endpoint.get_config)
  end

  it "rejects a request for configuration from a node with an invalid node secret" do
    post '/api/config', node_key: "invalid_test"
    expect(last_response).to be_ok
    expect(last_response.content_type).to eq("application/json")
    json = JSON.parse(last_response.body)
    expect(json).to have_key("node_invalid")
    expect(json["node_invalid"]).to eq(true)
  end

  it "updates an endpoints version from the user agent string" do
    @endpoint = Endpoint.last
    old_agent = @endpoint.last_version
    post '/api/config', {node_key: @endpoint.node_key}, {'HTTP_USER_AGENT' => "version2"}
    expect(last_response).to be_ok
    expect(last_response.content_type).to eq("application/json")
    @endpoint.reload
    expect(@endpoint.last_version).to eq("version2")
  end

# ConfigurationGroup management
  it "allows you to create a new configuration group" do
    pre_create_count = ConfigurationGroup.count
    post '/api/configuration_groups', {name: "api-test"}.to_json
    expect(last_response).to be_ok
    expect(last_response.content_type).to eq("application/json")
    expect(ConfigurationGroup.count).to eq(pre_create_count + 1)
    expect(ConfigurationGroup.last.name).to eq("api-test")
    response = JSON.parse(last_response.body)
    expect(response['status']).to eq("created")
    expect(response['configuration_group']['name']).to eq("api-test")
  end

  it "provides a reasonable error message when it fails to create a ConfigurationGroup" do
    pre_create_count = ConfigurationGroup.count
    post '/api/configuration_groups', {name: ""}.to_json # no name provided. Invalid object
    expect(last_response).to be_ok
    expect(last_response.content_type).to eq("application/json")
    expect(ConfigurationGroup.count).to eq(pre_create_count)
    response = JSON.parse(last_response.body)
    expect(response['status']).to eq("configuration group creation failed")
    expect(response.keys).to include("error")
  end

  it "allows you to get an index of ConfigurationGroups" do
    get '/api/configuration_groups'
    expect(last_response).to be_ok
    expect(last_response.content_type).to eq("application/json")
    response = JSON.parse(last_response.body)
    expect(response.length).to eq(ConfigurationGroup.count)
  end

  it "allows you to delete an empty ConfigurationGroup" do
    # Make something to delete
    pre_create_count = ConfigurationGroup.count
    post '/api/configuration_groups', {name: "api-test"}.to_json
    expect(last_response).to be_ok
    expect(last_response.content_type).to eq("application/json")
    response = JSON.parse(last_response.body)
    id = response['configuration_group']['id']
    delete "/api/configuration_groups/#{id}"
    expect(ConfigurationGroup.count).to eq(pre_create_count)
    response = JSON.parse(last_response.body)
    expect(response['status']).to eq('deleted')
  end

  it "doesn't allow you to delete a ConfigurationGroup that has endpoints" do
    @cg = ConfigurationGroup.first
    pre_create_count = ConfigurationGroup.count

    delete "/api/configuration_groups/#{@cg.id}"
    expect(last_response).to be_ok
    expect(last_response.content_type).to eq("application/json")
    expect(ConfigurationGroup.count).to eq(pre_create_count)
    response = JSON.parse(last_response.body)
    expect(response['status']).to eq('error')
    expect(response.keys).to include("error")
  end

  it "provides detailed information about a ConfigurationGroup" do
    @cg = ConfigurationGroup.first
    get "/api/configuration_groups/#{@cg.id}"
    expect(last_response).to be_ok
    expect(last_response.content_type).to eq("application/json")
    response = JSON.parse(last_response.body)

    expect(response['id']).to eq(@cg.id)
    expect(response['default_config_id']).to eq(@cg.default_config.id)
    expect(response['name']).to eq(@cg.name)
    expect(response['endpoint_count']).to eq(@cg.endpoints.count)
    expect(response['endpoint_ids']).to include(@cg.endpoints.first.id)
    expect(response['configuration_ids']).to include(@cg.configurations.first.id)
  end

  it "provides a reasonable error when a ConfigurationGroup is not found" do
    get "/api/configuration_groups/99999" # not likely to be in test database
    expect(last_response).to be_ok
    expect(last_response.content_type).to eq("application/json")
    response = JSON.parse(last_response.body)
    expect(response['status']).to eq('error')
    expect(response.keys).to include('error')
  end

  it "allows you to get a list of all Configurations belonging to a ConfigurationGroup" do
    @cg = ConfigurationGroup.first
    get "/api/configuration_groups/#{@cg.id}/configurations"
    expect(last_response).to be_ok
    expect(last_response.content_type).to eq("application/json")
    response = JSON.parse(last_response.body)
    expect(response.length).to eq(@cg.configurations.count)
  end

  it "allows you to add a Configuration to a ConfigurationGroup" do
    @cg = ConfigurationGroup.first
    pre_create_count = @cg.configurations.count
    post "/api/configuration_groups/#{@cg.id}/configurations", {name: "api-test",
      version: 1,
      notes: "this is a test",
      config_json: {test:"test"}.to_json.to_s}.to_json
    expect(last_response).to be_ok
    expect(last_response.content_type).to eq("application/json")
    response = JSON.parse(last_response.body)
    expect(response['status']).to eq('created')
    expect(response.keys).to include("config")
    expect(response['config']).to include('id')
    expect(response['config']['name']).to eq("api-test")
    expect(response['config']['version']).to eq(1)
    expect(response['config']['config_json']).to eq({test:"test"}.to_json)
    expect(response['config']['configuration_group_id']).to eq(@cg.id)
  end

# Configuration management
  it "allows you to create a new Configuration" do
    pre_create_count = @cg.configurations.count
    post "/api/configurations", {name: "api-test",
      version: 1,
      notes: "test",
      config_json: {test: "test"}.to_json,
      configuration_group_id: @cg.id}.to_json
    expect(last_response).to be_ok
    expect(last_response.content_type).to eq("application/json")
    response = JSON.parse(last_response.body)
    expect(response['status']).to eq('success')
    expect(response['config'].keys).to include('id')
    expect(response['config']['name']).to eq("api-test")
    expect(response['config']['version']).to eq(1)
    expect(response['config']['config_json']).to eq({test:"test"}.to_json)
    expect(response['config']['configuration_group_id']).to eq(@cg.id)
  end

  it "provides a resonable error message when it fails to create a Configuration" do
    pre_create_count = Configuration.count
    # missing configuration_group_id, not valid
    post "/api/configurations", {name: "api-test",
      version: 1,
      notes: "test",
      config_json: {test: "test"}.to_json}.to_json
    expect(last_response).to be_ok
    expect(last_response.content_type).to eq("application/json")
    response = JSON.parse(last_response.body)
    expect(response['status']).to eq('error')
    expect(response.keys).to include('error')
  end

  it "allows you to get an index of Configurations" do
    get "/api/configurations"
    expect(last_response).to be_ok
    expect(last_response.content_type).to eq("application/json")
    response = JSON.parse(last_response.body)
    expect(response.length).to eq(Configuration.all.count)
  end

  it "allows you to delete an unassigned Configuration from a ConfigurationGroup" do
    @cg = ConfigurationGroup.first
    @config = @cg.configurations.create!(name:"api-test", version:1, notes:"test", config_json: {test:"test"}.to_json)
    pre_delete_count = @cg.configurations.count
    delete "/api/configurations/#{@config.id}"
    expect(last_response).to be_ok
    expect(last_response.content_type).to eq("application/json")
    expect(@cg.configurations.count).to eq(pre_delete_count - 1)
    response = JSON.parse(last_response.body)
    expect(response['status']).to eq('deleted')
  end

  it "doesn't allow you to delete a Configuration with assigned endpoints" do
    @cg = ConfigurationGroup.first
    pre_delete_count = @cg.configurations.count
    delete "/api/configurations/#{@cg.configurations.first.id}"
    expect(last_response).to be_ok
    expect(last_response.content_type).to eq("application/json")
    expect(@cg.configurations.count).to eq(pre_delete_count)
    response = JSON.parse(last_response.body)
    expect(response['status']).to eq('error')
    expect(response.keys).to include('error')
  end

  it "provides detailed information about a Configuration" do
    @config = @cg.configurations.first
    get "/api/configurations/#{@config.id}"
    expect(last_response).to be_ok
    expect(last_response.content_type).to eq("application/json")
    response = JSON.parse(last_response.body)
    expect(response['id']).to eq(@config.id)
    expect(response['name']).to eq(@config.name)
    expect(response['version']).to eq(@config.version)
    expect(response['notes']).to eq(@config.notes)
    expect(response['config_json']).to eq(@config.config_json)
    expect(response['assigned_endpoint_count']).to eq(@config.assigned_endpoints.count)
    expect(response['assigned_endpoints']).to include(@config.assigned_endpoints.first.id)
    expect(response.keys).to include('configured_endpoints')
    expect(response['configured_endpoint_count']).to eq(@config.configured_endpoints.count)
  end

  it "provides a resonable error when a Configuration is not found" do
    get "/api/configurations/99999" # not likely to be in test database
    expect(last_response).to be_ok
    expect(last_response.content_type).to eq("application/json")
    response = JSON.parse(last_response.body)
    expect(response['status']).to eq('error')
    expect(response.keys).to include('error')
  end
end
