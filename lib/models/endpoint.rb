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

  validates :node_key, :assigned_config_id,  presence: true
  belongs_to :assigned_config, class_name: 'Configuration', foreign_key: 'assigned_config_id'
  belongs_to :last_config, class_name: 'Configuration', foreign_key: 'last_config_id'
  belongs_to :configuration_group
  after_initialize :post_init

  # For pagination
  self.per_page = 100


  def post_init
    self.config_count = self.config_count || 0
    if self.assigned_config_id.nil?
      self.assigned_config = self.configuration_group.default_config
    end
  end

  def get_config(params={})
    logdebug "returning json from configuration_id #{self.assigned_config.id}"
      self.config_count += 1
      self.last_config_time = Time.now
      self.last_config = self.assigned_config
      if params[:user_agent]
        self.last_version = params[:user_agent]
      end
      self.save
      self.assigned_config.config_json
  end

  def node_secret
    {"node_key": node_key}.to_json
  end

  def assigned_config
    begin
      GuaranteedConfiguration.find(assigned_config_id)
    rescue
      Configuration.new
    end
  end

  def last_config
    begin
      GuaranteedConfiguration.find(last_config_id)
    rescue
      Configuration.new
    end
  end
end

class GuaranteedEndpoint
  def self.find(id)
    Endpoint.find_by({id:id}) || MissingEndpoint.new
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

  def get_config(params = {})
    logdebug "Returning node_invalid to unknown endpoint"
    {"node_invalid": true}.to_json
  end

  def save
    false
  end

  def node_secret
    logdebug "sending failed enroll response to client"
    {"node_invalid": true}.to_json
  end
end
