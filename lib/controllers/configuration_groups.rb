namespace '/configuration-groups' do
  get  do
    @groups = ConfigurationGroup.order("canary_config_id, name")
    erb :"configuration_groups/index"
  end

  post do
    @cg = ConfigurationGroup.create(name: params[:name])
    redirect '/configuration-groups'
  end

  namespace '/:cg_id' do
    get do
      @cg = GuaranteedConfigurationGroup.find(params[:cg_id])
      @endpoints = @cg.endpoints.order('last_config_time is NULL, last_config_time DESC').page(params[:page])

      @default_config = @cg.default_config
      if @cg.canary_in_progress?
        flash.now[:notice] = "Canary deployment in progress."
      end
      erb :"configuration_groups/show"
    end

    post do
      @cg = GuaranteedConfigurationGroup.find(params[:cg_id])
      @cg.default_config = GuaranteedConfiguration.find(params[:default_config])
      @cg.save
      redirect "/configuration-groups/#{params[:cg_id]}"
    end

    delete do
      @cg = GuaranteedConfigurationGroup.find(params[:cg_id])
      begin
        @cg.destroy
        flash[:success] = "#{@cg.name} deleted successfully"
      rescue RuntimeError => error
        flash[:warning] = "Unable to delete #{@cg.name}: " + error.message
      ensure
        redirect "/configuration-groups"
      end
    end

    namespace '/canary' do

      get '/cancel' do
        @cg = GuaranteedConfigurationGroup.find(params[:cg_id])
        @cg.cancel_canary
        flash[:success] = "Cancelled the canary configuration and reassigned endpoints to default"
        redirect "/configuration-groups/#{params[:cg_id]}"
      end

      get '/promote' do
        @cg = GuaranteedConfigurationGroup.find(params[:cg_id])
        @cg.promote_canary
        flash[:success] = "Promoted the canary configuration to default and reassigned remaining endpoints"
        redirect "/configuration-groups/#{params[:cg_id]}"
      end

      get '/:config_id' do
        @cg = GuaranteedConfigurationGroup.find(params[:cg_id])

        # Not using GuaranteedConfiguration here because if you try to assign
        # a missing config as the canary we need to throw an error
        @newconfig = Configuration.find(params[:config_id])
        if @cg.canary_in_progress?
          flash.now[:notice] = "Canary deployment in progress."
        end

        erb :"configuration_groups/canary"
      end

      post '/:config_id' do
        @cg = GuaranteedConfigurationGroup.find(params[:cg_id])

        # Not using GuaranteedConfiguration here because if you try to assign
        # a missing config as the canary we need to throw an error
        @newconfig = Configuration.find(params[:config_id])

        if @cg.canary_in_progress? and @cg.canary_config != @newconfig
          flash[:warning] = "Cannot assign endpoints because a different canary is in progress"
          redirect "/configuration-groups/#{params[:cg_id]}"
        end
        if params['method'] == 'count'
          @cg.assign_config_count(@newconfig, params['count'].to_i)
          @cg.canary_config = @newconfig unless @cg.canary_in_progress?
          flash[:success] = "Assigned #{@newconfig.name} version #{@newconfig.version} to #{params['count']} endpoints."
        elsif params['method'] == 'percent'
          @cg.assign_config_percent(@newconfig, params['percent'].to_i)
          @cg.canary_config = @newconfig unless @cg.canary_in_progress?
          flash[:success] = "Assigned #{@newconfig.name} version #{@newconfig.version} to #{params['percent']}% of endpoints."
        else
          flash[:warning] = "No valid method provided"
        end
          redirect "/configuration-groups/#{params[:cg_id]}"
      end
    end


    post '/assign' do
      @cg = GuaranteedConfigurationGroup.find(params[:cg_id])
      params["assign_pct"].each do |key, value|
        if value != ""
          puts "Looks like you want to assign #{value} percent to #{key}"
          @config = GuaranteedConfiguration.find(key)
          @cg.assign_config_percent(@config, value.to_i)
          break
        end
      end
      {status:"ok"}.to_json
    end

    namespace '/configurations' do
      get '/new' do
        @cg = GuaranteedConfigurationGroup.find(params[:cg_id])
        @config = @cg.configurations.build
        erb :"configurations/new"
      end

      post do
        @cg = GuaranteedConfigurationGroup.find(params[:cg_id])
        puts "we're good"
        @config = @cg.configurations.build(params[:config])
        puts @config.inspect
        if @config.save
          redirect "/configuration-groups/#{@cg.id}"
        else
          @config.errors.messages.to_s
        end
      end

      get '/:config_id/edit' do
        @config = GuaranteedConfiguration.find(params[:config_id])
        @endpoints = @config.assigned_endpoints.order('last_config_time is NULL, last_config_time DESC').page(params[:page])
        erb :"configurations/edit"
      end

      post '/:config_id' do
        @config = Configuration.find(params[:config_id])
        @config.name = params[:name]
        @config.version = params[:version]
        @config.notes = params[:notes]

        if @config.assigned_endpoints.count == 0
          @config.config_json = params[:config_json]
        end

        if @config.save
          flash[:notice] = "Changes saved"
          redirect "/configuration-groups/#{params[:cg_id]}"
        else
          flash[:warning] = "Unable to save configuration. #{@config.errors.messages.to_s}"
          redirect "/configuration-groups/#{params[:cg_id]}/configurations/#{params[:config_id]}/edit"
        end

      end

      delete '/:config_id' do
        @config = GuaranteedConfiguration.find(params[:config_id])
        begin
          @config.destroy
          flash[:success] = "Configuration #{@config.name} successfully deleted."
        rescue RuntimeError => error
          flash[:warning] = "Unable to delete #{@config.name}: " + error.message
        ensure
          redirect "/configuration-groups/#{params[:cg_id]}"
        end
      end
    end
  end
end
