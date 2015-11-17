require 'json'
require 'sinatra/activerecord'
require_relative '../../environments'

class APIKey < ActiveRecord::Base
  # id
  # key index
  # notes
  # perms
  # user

  PERMS = %w(read read/write)

  validates :key, :perms, :user, presence: true
end
