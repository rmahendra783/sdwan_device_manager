require "socket"
require "json"
require "time"

server = TCPServer.new("127.0.0.1", 4567)
puts "Mock SD-WAN Gateway listening on http://127.0.0.1:4567..."

loop do
  Thread.start(server.accept) do |client|
    request_line = client.gets
    next unless request_line

    method, path, = request_line.split(" ")
    headers = {}

    while (line = client.gets) && (line != "\r\n")
      key, value = line.split(": ", 2)
      headers[key.downcase] = value.strip if key && value
    end

    body = ""
    if headers["content-length"]
      body = client.read(headers["content-length"].to_i)
    end

    case [method, path]
    when ["GET", "/api/v1/devices/EDGE-2432-AB/config"]
      puts "\n[Mock Gateway] -> GET running config for EDGE-2432-AB (matching desired)"
      response_data = {
        "system" => {
          "site_id" => 101,
          "system_ip" => "172.16.255.1",
          "organization" => "Global Logistics Corp"
        },
        "interfaces" => [
          { "name" => "eth0", "enabled" => true, "ip_address" => "192.168.1.1/24" },
          { "name" => "eth1", "enabled" => true, "ip_address" => "10.0.0.1/30" }
        ],
        "overlay_policy" => {
          "encryption" => "aes_gcm_256",
          "traffic_steering" => "prefer_broadband"
        }
      }.to_json

      client.print "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: #{response_data.bytesize}\r\nConnection: close\r\n\r\n#{response_data}"

    when ["POST", "/api/v1/devices/EDGE-2432-AB/config"]
      puts "\n[Mock Gateway] <- POST push config to EDGE-2432-AB: #{body}"
      response_data = { "status" => "applied", "applied_at" => Time.now.iso8601 }.to_json

      client.print "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: #{response_data.bytesize}\r\nConnection: close\r\n\r\n#{response_data}"

    else
      not_found = { "error" => "Not Found" }.to_json
      client.print "HTTP/1.1 404 Not Found\r\nContent-Type: application/json\r\nContent-Length: #{not_found.bytesize}\r\nConnection: close\r\n\r\n#{not_found}"
    end

    client.close
  end
rescue Interrupt
  puts "\nShutting down Mock Gateway."
  exit 0
end
