FactoryBot.define do
  factory :device_configuration do
    device { nil }
    version { 1 }
    desired_config { "" }
    running_config { "" }
    diff_payload { "" }
    status { "MyString" }
    applied_at { "2026-09-18 15:40:34" }
  end
end
