namespace '/apikeys' do
  get do
    @keys = APIKey.where user: current_user
    erb :"apikeys/index"
  end

  get '/new' do
    @key = APIKey.new
    @key.key = SecureRandom.uuid
    erb :"apikeys/new"
  end
end
