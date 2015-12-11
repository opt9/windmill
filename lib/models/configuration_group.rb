require 'json'
require 'sinatra/activerecord'
require_relative '../../environments'

class ConfigurationGroup < ActiveRecord::Base
  # name, string
  # default_config_id, integer

  validates :name, presence: true
  has_many :configurations
  has_many :endpoints

  before_destroy do
    if self.endpoints.count > 0
      raise "Cannot delete ConfigurationGroup while it has endpoints"
    end

    if self.name == "default"
      raise "Cannot delete the default configuration group"
    end
  end


  def default_config
    config_id = self.default_config_id || self.configurations.first
    GuaranteedConfiguration.find(config_id)
  end

  def default_config=(in_config)
    self.default_config_id = in_config.id
  end

  def canary_config
    GuaranteedConfiguration.find(self.canary_config_id)
  end

  def canary_config=(in_config)
    if self.canary_in_progress?
      raise "Canary currently in progress. Cancel existing canary before setting a canary"
    end
    self.canary_config_id = in_config.id
    self.save
  end

  def canary_in_progress?
    !!self.canary_config_id
  end

  def cancel_canary
    self.assign_config_percent(self.default_config, 100)
    self.canary_config_id = nil
    self.save
  end

  def promote_canary
    if !self.canary_in_progress?
      raise "No canary in progress. Cannot promote what doesn't exist."
    end
    self.assign_config_percent(self.canary_config, 100)
    self.default_config = self.canary_config
    self.canary_config_id = nil
    self.save
  end

  def assign_config_percent(config, in_percent)
    begin
      if in_percent.to_i > 100
        return false
      end
      if in_percent.to_i <= 0
        return false
      end
    rescue
      return false
    end
    if !self.configurations.include?(config)
      return false
    end

    total_assignment_count = (self.endpoints.count * in_percent / 100.0).to_i
    self.assign_config_count(config, total_assignment_count)
  end

  def assign_config_count(config, in_count)
    number_todo = [in_count, self.endpoints.count].min

    # Here are the endpoints that already have the config being assigned
    already_done = self.endpoints.where(assigned_config: config).count

    number_todo = number_todo - already_done

    # Shuffle the rest of the endpoints
    remaining = self.endpoints.where.not(assigned_config: config).shuffle

    # now get the front of the whole list and assign configurations
    remaining[0,number_todo].each do |e|
      e.assigned_config = config
      e.save
    end
    true
  end

end


class GuaranteedConfigurationGroup
  def self.find(id)
    ConfigurationGroup.find_by({id: id}) || ConfigurationGroup.find_by(name: "default")
  end

  def self.find_by(in_hash)
    logdebug "searching for a ConfigurationGroup #{in_hash.inspect}"
    ConfigurationGroup.find_by(in_hash) || ConfigurationGroup.find_by(name: "default")
  end
end
