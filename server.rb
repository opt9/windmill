require 'sinatra'
require 'sinatra/namespace'
require 'sinatra/flash'
require 'json'
require 'omniauth'
require 'omniauth-github'
require 'omniauth-heroku'
require 'omniauth-google-oauth2'
require 'securerandom'
require 'encrypted_cookie'
require 'time_difference'
require_relative 'lib/models/endpoint'
require_relative 'lib/models/configuration'
require_relative 'lib/models/configuration_group'
require_relative 'lib/models/enroller'

NODE_ENROLL_SECRET = ENV['NODE_ENROLL_SECRET'] || "valid_test"

use Rack::Session::EncryptedCookie, expire_after: 86_400, secret: ENV['COOKIE_SECRET'] || SecureRandom.hex(64)
use OmniAuth::Builder do
  provider :github, ENV['GITHUB_KEY'], ENV['GITHUB_SECRET'], scope: "user:email"
  provider :heroku, ENV['HEROKU_KEY'], ENV['HEROKU_SECRET'], fetch_info: true, scope: "identity"
  provider :google_oauth2, ENV['GOOGLE_ID'], ENV['GOOGLE_SECRET'], name: 'google'
end

if ENV['FULL_URL']
  OmniAuth.config.full_host = ENV['FULL_URL']
end

def logdebug(message)
  if ENV['OSQUERYDEBUG']
    puts "\n" + caller_locations(1,1)[0].label + ": " + message
  end
end

configure do
  if ENV['RACK_ENV'] != 'test'
    if ENV['AUTHORIZEDUSERS']
      set :authorized_users, ENV['AUTHORIZEDUSERS'].split(',')
    else
      begin
        set :authorized_users, File.open('authorized_users.txt').readlines.map {|line| line.strip}
      rescue
        raise ArgumentError, "No ENV or file for authorized users. See: https://github.com/heroku/windmill#authentication-and-logging-in"
      end
    end
  end
end

before do
  pass if request.path_info =~ /^\/auth\//
  pass if request.path_info =~ /^\/api\//
  pass if request.path_info =~ /^\/status/
  redirect to('/auth/login') unless current_user
end

helpers do
  def current_user
    session[:email] || nil
  end

  def bootflash
    remapper = {notice: "alert alert-info", success: "alert alert-success", warning: "alert alert-danger"}
    flash.collect {|k, v| "<div class=\"#{remapper[k]}\">#{v}</div>"}.join
  end

  def difftime(oldtime, newtime)
    oldtime = oldtime || DateTime.now
    diff = TimeDifference.between(oldtime, newtime).in_each_component
    returnstring = "never"
    diff.each do |key, value|
      if value >= 1
        returnstring = "#{value.to_i} #{key.to_s.singularize.pluralize(value.to_i)}"
        break
      end
    end
    returnstring
  end
end

get '/status' do
  "running at #{Time.now}"
end

get '/' do
  redirect '/configuration-groups'
end

namespace '/auth' do
  get '/login' do
    erb :"auth/login", layout: :'login_layout'
  end

  get '/:provider/callback' do
    logdebug JSON.pretty_generate(request.env['omniauth.auth'])
    email = env['omniauth.auth']['info']['email']
    if settings.authorized_users.include? email
      session[:email] = email
      flash[:notice] = "#{email} logged in successfully."
      redirect to('/')
    end
    flash[:warning] = "#{email} logged in successfully but not authorized in authorized_users.txt"
    redirect to('/auth/login')
  end

  get '/failure' do
    flash[:warning] = "Authentication failed."
    redirect to('/auth/login')
    # erb "<h1>Authentication Failed:</h1><h3>message:<h3> <pre>#{params}</pre>"
  end

  get '/:provider/deauthorized' do
    erb "#{params[:provider]} has deauthorized this app."
  end

  get '/logout' do
    email = session[:email]
    session[:email] = nil
    flash[:notice] = "#{email} logged out successfully."
    redirect to('/')
  end
end

namespace '/api' do
  get '/status' do
    {"status": "running", "timestamp": Time.now}.to_json
  end

  namespace '/configurations' do
    # CRUD CONFIG

    post '/new' do
      # TODO Create: Configuration
      json_data = JSON.parse(request.body.read)
      @c = Configuration.create(name: json_data['name'], config_json: json_data['configuration'], version: json_data['version'], notes: json_data['notes'])
      @c.save
      {'status': 'created', 'configuration': @c}.to_json
    end

    get do
      # Read: All Configurations
      Configuration.all.to_json
    end

    get '/:configuration_id' do
      # Read: One Configuration
      begin
        Configuration.find(params['configuration_id']).to_json
      rescue
        {'status': 'configuration not found'}.to_json
      end
    end

    patch '/:configuration_id' do
      # Update: Configuration
      {'status': 'Configuration modification via the Windmill API is not supported.'}.to_json
    end

    delete '/:configuration_id' do
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

    post '/new' do
      # Create: Configuration Group
      begin
        json_data = JSON.parse(request.body.read)
        @cg = ConfigurationGroup.create(name: json_data['name'])
        {'status': 'created', 'configuration_group': @cg}.to_json
      rescue
        {'status': 'configuration group creation failed'}.to_json
      end
    end

    get do
      # Read: All Configuration Groups
      ConfigurationGroup.all.to_json
    end

    get '/:configuration_group_id' do
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
      # Update: Configuration Group
      {'status': 'configuration group modification via the Windmill API is not supported'}.to_json
    end

    delete '/:configuration_group_id' do
      # Delete: Configuration Group
      begin
        @e = ConfigurationGroup.find(params['configuration_group_id'])
        @e.destroy
        {'status': 'deleted'}.to_json
      rescue
        {'status': 'endpoint not found'}.to_json
      end
    end
  end

  namespace '/endpoints' do
    post do
      # Create: Endpoint. Not implimented deliberately. Should be registered by osquery.
      {'status': 'endpoint creation via the Windmill API is not supported'}.to_json
    end

    get do
      # Read: All Endpoints
      begin
        Endpoint.all.to_json
      rescue
        {'status': 'no endpoints found'}.to_json
      end
    end

    get '/:endpoint_id' do
      # Read: One Endpoint
      begin
        Endpoint.find(params['endpoint_id']).to_json
      rescue
        {'status': 'endpoint not found'}.to_json
      end
    end

    patch '/:endpoint' do
      # Update: Not implimented deliberately. Should be updated by osquery.
      {'status': 'endpoint updating via the Windmill API is not supported'}.to_json
    end

    delete '/:endpoint_id' do
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

  namespace '/enroll' do

    post do
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
end

namespace '/configuration-groups' do
  get  do
    @groups = ConfigurationGroup.all
    erb :"configuration_groups/index"
  end

  post do
    @cg = ConfigurationGroup.create(name: params[:name])
    redirect '/configuration-groups'
  end

  namespace '/:cg_id' do
    get do
      @cg = GuaranteedConfigurationGroup.find(params[:cg_id])
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
