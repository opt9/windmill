require 'sinatra/activerecord'
require_relative '../../environments'
require 'securerandom'
require 'json'

class Endpoint < ActiveRecord::Base
  # node_key, string
  # last_version, string
  # config_count, integer
  # configuration_id, integer
  # last_config_time, datetime
  # last_ip, string
  # identifier, string
  # group_label, string
  # default ruby timestamps

  validates :node_key, :configuration_id,  presence: true
  belongs_to :configuration
  belongs_to :configuration_group

  def self.enroll(in_key, params)
    enroll_secret, group_label, identifier = in_key.split(':').reverse
    logdebug "received enroll_secret " + in_key.to_s
    logdebug "extrapolated enroll_secret " + enroll_secret.to_s

    if enroll_secret != NODE_ENROLL_SECRET
      logdebug "invalid enroll_secret. Returning MissingEndpoint"
      MissingEndpoint.new
    else
      params.merge! node_key: SecureRandom.uuid, config_count: 0,
        identifier: identifier, group_label: group_label, configuration_id: 1
      logdebug "valid enroll_secret. Creating new endpoint - #{params}"
      Endpoint.create params
    end
  end

  def get_config
    logdebug "returning json from configuration_id #{self.configuration_id}"
    self.configuration.config_json
  end

  def node_secret
    {"node_key": node_key}.to_json
  end
end

class GuaranteedEndpoint
  def self.find(id)
    begin
      Endpoint.find(id)
    rescue
      MissingEndpoint.new
    end
  end

  def self.find_by(in_hash)
    logdebug "searching for endpoint with these values: #{in_hash.inspect}"
    Endpoint.find_by(in_hash) || MissingEndpoint.new
  end
end

class MissingEndpoint
  attr_accessor :node_key, :config_count, :last_version,
    :last_config_time, :last_ip, :created_at, :updated_at,
    :identifier, :group_label

  def initialize
    @node_key = "missing endpoint"
    @last_version = "missing endpoint"
    @config_count = 0
    @last_config_time = Time.now
    @last_ip = "missing endpoint"
    @created_at = Time.now
    @updated_at = Time.now
    @identifer = "missing endpoint"
    @group_label = "missing endpoint"
  end

  def valid?
    false
  end

  def get_config(filename="default")
    FAILED_ENROLL_RESPONSE.to_json
  end

  def save
    false
  end

  def node_secret
    logdebug "sending failed enroll response to client"
    FAILED_ENROLL_RESPONSE.to_json
  end
end
