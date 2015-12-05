namespace '/api' do

  get '/status' do
    content_type :json
    {"status": "running", "timestamp": Time.now}.to_json
  end

  post '/enroll' do
    content_type :json
    # This next line is necessary if you want to test with curl without
    # using the -H option
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
      content_type :json
      # This next line is necessary if you want to test with curl without
      # using the -H option
    begin
      params.merge!(JSON.parse(request.body.read))
    rescue
    end
    logdebug "value in node_key is #{params['node_key']}"
    client = GuaranteedEndpoint.find_by node_key: params['node_key']
    logdebug "Received endpoint: #{client.inspect}"
    client.get_config user_agent: request.user_agent
  end

  namespace '/configurations' do
    # CRUD CONFIG

    post do
      content_type :json
      error 401 unless apivalid?(params[:key], perm: :write)
      json_data = JSON.parse(request.body.read)
      # Create: Configuration
      begin
        @cg = ConfigurationGroup.find(json_data['configuration_group_id'])
      rescue ActiveRecord::RecordNotFound => e
        return {'status': 'error', error: e.message}.to_json
      end

      @c = @cg.configurations.build(name: json_data['name'],
        config_json: json_data['config_json'],
        version: json_data['version'],
        notes: json_data['notes'])
      if @c.save
        {'status': 'success', 'config': @c}.to_json
      else
        {'status': 'error', 'error': @c.errors}.to_json
      end
    end

    get do
      content_type :json
      error 401 unless apivalid?(params[:key])
      # Read: All Configurations
      Configuration.all.to_json
    end

    namespace '/:config_id' do
      delete do
        content_type :json
        error 401 unless apivalid?(params[:key], perm: :write)
        begin
          @config = Configuration.find(params[:config_id])
          @config.destroy
          {status: 'deleted'}.to_json
        rescue RuntimeError => e
          {'status': 'error', error: e.message}.to_json
        end
      end

      get do
        # Read: One Configuration
        content_type :json
        error 401 unless apivalid?(params[:key])
        begin
          @config = Configuration.find(params[:config_id])
          response = {id: @config.id,
            name: @config.name,
            version: @config.version,
            notes: @config.notes,
            config_json: @config.config_json,
            assigned_endpoints: @config.assigned_endpoints.map {|e| e.id},
            assigned_endpoint_count: @config.assigned_endpoints.count,
            configured_endpoints: @config.configured_endpoints.map {|e| e.id},
            configured_endpoint_count: @config.configured_endpoints.count}.to_json
        rescue ActiveRecord::RecordNotFound => e
          return {'status': 'error', error: e.message}.to_json
        end
      end

      patch do
        content_type :json
        error 401 unless apivalid?(params[:key], perm: :write)
        json_data = JSON.parse(request.body.read)
        begin
          @config = Configuration.find(params[:config_id])

          if @config.assigned_endpoints.count > 0 and json_data.keys.include? "config_json"
            return {status: "error", error: "Cannot modify config_json when Configuration has assigned endpoints."}.to_json
          end

          ["name", "version", "notes", "config_json"].each do |key|
            if json_data[key]
              @config[key] = json_data[key]
            end
          end

          if @config.save
            return {status: "success", config: @config}.to_json
          else
            return {status: "error", error: @config.errors}
          end

        rescue ActiveRecord::RecordNotFound => e
          return {'status': 'error', error: e.message}.to_json
        end
      end
    end # end namespace /configurations/:config_id
  end # end namespace /configurations

  namespace '/configuration_groups' do

    post do
      # Create: Configuration Group
      content_type :json
      error 401 unless apivalid?(params[:key], perm: :write)

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
      error 401 unless apivalid?(params[:key])
      ConfigurationGroup.all.to_json
    end

    namespace '/:cg_id' do
      delete do
        content_type :json
        error 401 unless apivalid?(params[:key], perm: :write)
        # Delete: Configuration Group
        begin
          @cg = ConfigurationGroup.find(params[:cg_id])
          @cg.destroy
          {'status': 'deleted'}.to_json
        rescue RuntimeError => e
          {'status': 'error', error: e.message}.to_json
        end
      end

      get do
        content_type :json
        error 401 unless apivalid?(params[:key])
        begin
          @cg = ConfigurationGroup.find(params[:cg_id])
          response = {id: @cg.id,
            name: @cg.name,
            default_config_id: @cg.default_config.id,
            endpoint_count: @cg.endpoints.count,
            endpoint_ids: @cg.endpoints.map {|e| e.id },
            configuration_ids: @cg.configurations.map {|c| c.id}}
          response.to_json
        rescue ActiveRecord::RecordNotFound => e
          return {'status': 'error', error: e.message}.to_json
        end
      end

      patch do
        content_type :json
        error 401 unless apivalid?(params[:key], perm: :write)
        {'status': 'configuration group modification via the Windmill API is not supported'}.to_json
      end

      namespace '/configurations' do
        get do
          content_type :json
          error 401 unless apivalid?(params[:key])
          @cg = ConfigurationGroup.find(params[:cg_id])
          @cg.configurations.to_json
        end

        post do
          content_type :json
          error 401 unless apivalid?(params[:key], perm: :write)
          json_data = JSON.parse(request.body.read)
          @cg = ConfigurationGroup.find(params[:cg_id])
          @config = @cg.configurations.build(name: json_data['name'],
            version: json_data['version'],
            notes: json_data['notes'],
            config_json: json_data['config_json'])

          if @config.save
            {status: "created", config: @config}.to_json
          else
            {status: "Configuration creation failed.", error: @config.errors}.to_json
          end
        end
      end # end namespace /configuration_groups/:cg_id/configurations
    end # end namespace /configuration_groups/:cg_id
  end # end namespace /configuration_groups

  namespace '/endpoints' do
    post do
      content_type :json
      error 401 unless apivalid?(params[:key], perm: :write)
      # Create: Endpoint. Not implimented deliberately. Should be registered by osquery.
      {'status': 'endpoint creation via the Windmill API is not supported'}.to_json
    end

    get do
      content_type :json
      error 401 unless apivalid?(params[:key])
      # Read: All Endpoints
      begin
        Endpoint.all.to_json
      rescue
        {'status': 'no endpoints found'}.to_json
      end
    end

    get '/:endpoint_id' do
      content_type :json
      error 401 unless apivalid?(params[:key])
      # Read: One Endpoint
      begin
        Endpoint.find(params['endpoint_id']).to_json
      rescue
        {'status': 'endpoint not found'}.to_json
      end
    end

    patch '/:endpoint' do
      content_type :json
      error 401 unless apivalid?(params[:key], perm: :write)
      # Update: Not implimented deliberately. Should be updated by osquery.
      {'status': 'endpoint updating via the Windmill API is not supported'}.to_json
    end

    delete '/:endpoint_id' do
      content_type :json
      error 401 unless apivalid?(params[:key], perm: :write)
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

end # end /api namespace