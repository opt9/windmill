require 'json'
require 'sinatra/activerecord'
require_relative '../../environments'

class APIKey < ActiveRecord::Base
  # id
  # key index
  # notes
  # perms

  PERMS = %w(read read/write)

  validates :perms, presence: true

  before_create :generate_random_key

  def generate_random_key
    self.key = SecureRandom.hex(32)
  end
end
