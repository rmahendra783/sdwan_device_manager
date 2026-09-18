# app/services/sdwan_gateway_client.rb
class SdwanGatewayClient
  class NetworkError < StandardError; end
  class DeviceUnreachableError < NetworkError; end
  class AuthenticationError < NetworkError; end

  BASE_URL = ENV.fetch("SDWAN_GATEWAY_URL", "https://api.internal-network.local")
  DEFAULT_TIMEOUT = 5
  DEFAULT_OPEN_TIMEOUT = 2

  def initialize(auth_token: ENV.fetch("SDWAN_GATEWAY_TOKEN", "mock-token-xyz"))
    @auth_token = auth_token
  end

  def fetch_running_config(serial_number)
    response = connection.get("/api/v1/devices/#{serial_number}/config")
    handle_response(response)
  rescue Faraday::TimeoutError
    raise DeviceUnreachableError, "Gateway timed out reaching device #{serial_number}"
  rescue Faraday::ConnectionFailed => e
    if e.message =~ /execution expired|timed? ?out/i
      raise DeviceUnreachableError, "Gateway timed out reaching device #{serial_number}"
    end
    raise NetworkError, "Connection failure to SD-WAN gateway: #{e.message}"
  end

  def push_configuration(serial_number, config_payload)
    response = connection.post("/api/v1/devices/#{serial_number}/config") do |req|
      req.body = config_payload.to_json
    end
    handle_response(response)
  rescue Faraday::TimeoutError
    raise DeviceUnreachableError, "Gateway timed out pushing config to #{serial_number}"
  rescue Faraday::ConnectionFailed => e
    if e.message =~ /execution expired|timed? ?out/i
      raise DeviceUnreachableError, "Gateway timed out pushing config to #{serial_number}"
    end
    raise NetworkError, "Connection failure to SD-WAN gateway: #{e.message}"
  end

  private

  def connection
    @connection ||= Faraday.new(url: BASE_URL) do |builder|
      builder.request :json
      builder.headers["Authorization"] = "Bearer #{@auth_token}"
      builder.headers["Content-Type"] = "application/json"
      builder.options.timeout = DEFAULT_TIMEOUT
      builder.options.open_timeout = DEFAULT_OPEN_TIMEOUT
      builder.adapter Faraday.default_adapter
    end
  end

  def handle_response(response)
    case response.status
    when 200..299
      response.body.is_a?(String) ? JSON.parse(response.body) : response.body
    when 401, 403
      raise AuthenticationError, "Gateway rejected credentials: #{response.body}"
    when 404
      raise DeviceUnreachableError, "Device not found on network gateway"
    else
      raise NetworkError, "Gateway returned HTTP #{response.status}: #{response.body}"
    end
  end
end