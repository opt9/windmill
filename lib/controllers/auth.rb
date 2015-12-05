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
  
  if settings.test?
    get '/bypass' do
      logdebug "bypass login in test environment"
      session[:email] = "test@test.com"
      redirect to('/')
    end
  end
end
