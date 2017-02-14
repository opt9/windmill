configure :test do
  set :database, 'sqlite3:db/test.sqlite3'
  set :show_exceptions, true
end

configure :development do
  set :database, 'sqlite3:db/development.sqlite3'
  set :show_exceptions, true
end

configure :staging do
  ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'] || 'postgres://localhost/mydb')
end

configure :production do
  ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'] || 'postgres://localhost/mydb')
end
