namespace '/apikeys' do
  get do
    @keys = APIKey.find user: current_user
    erb :"apikeys/index"
  end

  get '/new' do
    erb :"apikeys/new"
  end
end
