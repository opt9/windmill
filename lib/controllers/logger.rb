require 'logstash-logger'

logger_type = ENV['LOGGER_TYPE'] || nil
logger_path = ENV['LOGGER_PATH'] || nil
logger_port = ENV['LOGGER_PORT'] || nil

if logger_type == 'file' and logger_path
  logger = LogStashLogger.new(type: :file, path: 'test.log', sync: true)
elsif logger_type == 'tcp' and logger_host
  logger = LogStashLogger.new(type: :tcp, host: 'localhost', port: logger_port)
else
  logger = LogStashLogger.new(type: :stdout)
end

raise "No logging output defined." if logger.nil?

# Eventually it needs to ensure that endpoints are enrolled (pulled from api.rb:/config)
# logdebug "value in node_key is #{params['node_key']}"
# client = GuaranteedEndpoint.find_by node_key: params['node_key']

namespace '/logger' do
  post do
    puts "Inbound log!"
    # Add Check that Endpoint is Valid

    begin
      log = JSON.parse(request.body.read)
    rescue
    end
    logger.info "#{log}"

    {"node_invalid": false}.to_json
  end
end
