Untappd.configure do |config|
  config.client_id = Rails.application.credentials.untappd[:client_id]
  config.client_secret = Rails.application.credentials.untappd[:client_secret]
  config.gmt_offset = 3
end
