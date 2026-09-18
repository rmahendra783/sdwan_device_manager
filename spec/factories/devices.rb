FactoryBot.define do
  factory :device do
    account { nil }
    site { nil }
    hostname { "MyString" }
    serial_number { "MyString" }
    management_ip { "" }
    device_model { "MyString" }
    device_role { "MyString" }
    sync_status { "MyString" }
  end
end
