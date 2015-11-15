namespace '/api' do
  get '/status' do
    {"status": "running", "timestamp": Time.now}.to_json
  end

  namespace '/configurations' do
    # CRUD CONFIG

    post '/new' do
      content_type :json
      # Create: Configuration
      json_data = JSON.parse(request.body.read)

      if json_data['cg_id']

        @cg = ConfigurationGroup.find(json_data['cg_id'])
        @c = @cg.configurations.build(name: json_data['name'], config_json: json_data['configuration'], version: json_data['version'], notes: json_data['notes'])
        @c.save
        if @c.save
          {'status': 'created', 'configuration': @c}.to_json
        else
          {'status': 'configuration creation failed', 'error': @c.errors}.to_json
        end
      else
        {'status': 'no configuration group specified'}.to_json
      end
    end

    get do
      content_type :json
      # Read: All Configurations
      Configuration.all.to_json
    end

    get '/:configuration_id' do
      content_type :json
      # Read: One Configuration
      begin
        Configuration.find(params['configuration_id']).to_json
      rescue
        {'status': 'configuration not found'}.to_json
      end
    end

    patch '/:configuration_id' do
      content_type :json
      # Update: Configuration
      {'status': 'Configuration modification via the Windmill API is not supported.'}.to_json
    end

    delete '/:configuration_id' do
      content_type :json
      # Delete: Configuration

      begin
        @c = Configruation.find(params['configuration_id'])
        @c.destroy
        {'status': 'deleted'}.to_json
      rescue
        {'status': 'configuration not found'}.to_json
      end
    end
  end

  namespace '/configuration_groups' do

    post do
      # Create: Configuration Group
      content_type :json

      json_data = JSON.parse(request.body.read)
      @cg = ConfigurationGroup.create(name: json_data['name'])
      if @cg.save
        {'status': 'created', 'configuration_group': @cg}.to_json
      else
        {'status': 'configuration group creation failed', error: @cg.errors}.to_json
      end

    end

    get do
      # Read: All Configuration Groups
      content_type :json
      ConfigurationGroup.all.to_json
    end

    get '/:configuration_group_id' do
      content_type :json
      # Read: One Configuration Group
      begin
        @e = ConfigruationGroup.find(params['configuration_group_id'])
        @e.destroy
        {'status': 'deleted'}.to_json
      rescue
        {'status': 'configuration group not found'}.to_json
      end
    end

    patch '/:configuration_group_id' do
      content_type :json
      # Update: Configuration Group
      {'status': 'configuration group modification via the Windmill API is not supported'}.to_json
    end

    delete '/:configuration_group_id' do
      content_type :json
      # Delete: Configuration Group
      begin
        @cg = ConfigurationGroup.find(params['configuration_group_id'])
        @cg.destroy
        {'status': 'deleted'}.to_json
      rescue RuntimeError => e
        {'status': 'error', error: e.message}.to_json
      end
    end

    post '/:cg_id/configuration/new' do
      content_type :json
      # Create: Configuration

      json_data = JSON.parse(request.body.read)

      if params['cg_id']
        @cg = ConfigurationGroup.find(params['cg_id'])
        @c = @cg.configurations.build(name: json_data['name'], config_json: json_data['configuration'], version: json_data['version'], notes: json_data['notes'])
        @c.save
        if @c.save
          return {'status': 'created', 'configuration': @c}.to_json
        else
          return {'status': 'configuration creation failed', 'error': @c.errors}.to_json
        end
      else
        return {'status': 'no configuration group specified'}.to_json
      end
    end
  end

  namespace '/endpoints' do
    post do
      content_type :json
      # Create: Endpoint. Not implimented deliberately. Should be registered by osquery.
      {'status': 'endpoint creation via the Windmill API is not supported'}.to_json
    end

    get do
      content_type :json
      # Read: All Endpoints
      begin
        Endpoint.all.to_json
      rescue
        {'status': 'no endpoints found'}.to_json
      end
    end

    get '/:endpoint_id' do
      content_type :json
      # Read: One Endpoint
      begin
        Endpoint.find(params['endpoint_id']).to_json
      rescue
        {'status': 'endpoint not found'}.to_json
      end
    end

    patch '/:endpoint' do
      content_type :json
      # Update: Not implimented deliberately. Should be updated by osquery.
      {'status': 'endpoint updating via the Windmill API is not supported'}.to_json
    end

    delete '/:endpoint_id' do
      content_type :json
      # Delete: One Endpoint
      begin
        @e = Endpoint.find(params['endpoint_id'])
        @e.destroy
        {'status': 'deleted'}.to_json
      rescue
        {'status': 'endpoint not found'}.to_json
      end
    end
  end


  post '/enroll' do
    # This next line is necessary because osqueryd does not send the
    # enroll_secret as a POST param.
    begin
      json_data = JSON.parse(request.body.read)
      params.merge!(json_data)
    rescue
    end

    @endpoint = Enroller.enroll params['enroll_secret'],
      last_version: request.user_agent,
      last_ip: request.ip
    @endpoint.node_secret
  end

  post '/config' do
    # This next line is necessary because osqueryd does not send the
    # enroll_secret as a POST param.
    begin
      params.merge!(JSON.parse(request.body.read))
    rescue
    end
    logdebug "value in node_key is #{params['node_key']}"
    client = GuaranteedEndpoint.find_by node_key: params['node_key']
    logdebug "Received endpoint: #{client.inspect}"
    client.get_config user_agent: request.user_agent
  end
end
