# config/initializers/sidekiq.rb
redis_config = {
  url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1"),
  network_timeout: 5,
  ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE } # Safe fallback for dev/staging redis connections
}

# Configures the Sidekiq background worker process
Sidekiq.configure_server do |config|
  config.redis = redis_config

  # Optional logger configuration for structured job tracing
  config.logger.level = Rails.env.production? ? Logger::INFO : Logger::DEBUG
end

# Configures the Rails Puma/web application process (enqueuing jobs)
Sidekiq.configure_client do |config|
  config.redis = redis_config
end