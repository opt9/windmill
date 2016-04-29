class Enroller
  def self.enroll(in_key, params)
    enroll_secret, group_label, identifier = in_key.split(':').reverse
    logdebug "received enroll_secret " + in_key.to_s
    logdebug "extrapolated enroll_secret " + enroll_secret.to_s
    logdebug "extrapolated group_label " + group_label.to_s
    logdebug "extrapolated identifier " + identifier.to_s

    if !Rack::Utils.secure_compare(enroll_secret, NODE_ENROLL_SECRET)
      logdebug "invalid enroll_secret. Returning MissingEndpoint"
      MissingEndpoint.new
    else
      logdebug "enroll secret is valid. Finding Configuration group: #{group_label}"
      @cg = GuaranteedConfigurationGroup.find_by name: group_label
      logdebug "received a ConfigurationGroup: #{@cg.inspect}"
      # logdebug "ConfigurationGroup has a default_config of: #{@cg.default_config}"
      if @cg.configurations.count == 0
        logdebug "ConfigurationGroup has no configurations. Returning default"
        @cg = GuaranteedConfigurationGroup.find_by name: "default"
      end
      params.merge!(assigned_config_id: @cg.default_config,
        node_key: SecureRandom.uuid,
        config_count: 0,
        group_label: group_label,
        identifier: identifier)
      logdebug "valid enroll_secret. Creating new endpoint - #{params}"
      @cg.endpoints.create params
    end
  end
end
