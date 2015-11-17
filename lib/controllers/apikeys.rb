namespace '/apikeys' do
  get do
    @keys = APIKey.where user: current_user
    erb :"apikeys/index"
  end

  post do
    puts '#################'
    @key = APIKey.new params[:apikey]
    @key.user = current_user
    puts @key.inspect

    if @key.save
      flash[:notice] = "Key created successfully"
      redirect "/apikeys"
    else
      flash[:warning] = @key.errors.messages.to_s
      redirect "/apikeys/new"
    end
  end

  get '/new' do
    @key = APIKey.new
    @key.key = SecureRandom.uuid
    erb :"apikeys/new"
  end
end
