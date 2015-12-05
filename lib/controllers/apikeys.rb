namespace '/apikeys' do
  get do
    @keys = APIKey.all
    erb :"apikeys/index"
  end

  post do
    @key = APIKey.new params[:apikey]

    if @key.save
      flash[:notice] = "Key created successfully: #{@key.key}"
      redirect "/apikeys"
    else
      flash[:warning] = @key.errors.messages.to_s
      redirect "/apikeys/new"
    end
  end

  get '/new' do
    # @key = APIKey.new
    # @key.key = SecureRandom.uuid
    erb :"apikeys/new"
  end

  namespace '/:key_id' do
    delete do
      begin
        @key = APIKey.find(params[:key_id])
      rescue ActiveRecord::RecordNotFound => e
        flash[:warning] = "Key not found"
      end

      if @key.destroy
        flash[:notice] = "Key destroyed"
      else
        flash[:warning] = "Failed to destroy key. #{@key.errors.messages.to_s}"
      end

      redirect "/apikeys"
    end
  end
end
