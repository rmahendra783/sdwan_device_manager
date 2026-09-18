# app/services/config_diff_service.rb
class ConfigDiffService
  Result = Struct.new(:has_drift?, :diff, keyword_init: true)

  def self.call(desired:, running:)
    new(desired: desired, running: running).call
  end

  def initialize(desired:, running:)
    @desired = (desired || {}).deep_stringify_keys
    @running = (running || {}).deep_stringify_keys
  end

  def call
    diff = compute_diff(@desired, @running)
    Result.new(
      has_drift?: diff.values.any?(&:present?),
      diff: diff
    )
  end

  private

  def compute_diff(desired, running)
    {
      missing: find_missing(desired, running),       # In desired, missing on device
      unexpected: find_missing(running, desired),    # On device, unapproved in desired
      modified: find_modified(desired, running)      # Present in both, but values differ
    }
  end

  def find_missing(source, target)
    source.each_with_object({}) do |(key, value), acc|
      unless target.key?(key)
        acc[key] = value
        next
      end

      if value.is_a?(Hash) && target[key].is_a?(Hash)
        nested = find_missing(value, target[key])
        acc[key] = nested if nested.present?
      end
    end
  end

  def find_modified(desired, running)
    desired.each_with_object({}) do |(key, desired_val), acc|
      next unless running.key?(key)

      running_val = running[key]

      if desired_val.is_a?(Hash) && running_val.is_a?(Hash)
        nested = find_modified(desired_val, running_val)
        acc[key] = nested if nested.present?
      elsif desired_val != running_val
        acc[key] = {
          "desired" => desired_val,
          "running" => running_val
        }
      end
    end
  end
end