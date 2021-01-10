require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Buhlib
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0
    config.hosts.clear
    config.time_zone = 'Moscow'

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    Rails.application.routes.default_url_options[:host] = 'https://51476cacf6dd.ngrok.io'
    # Rails.application.routes.default_url_options[:host] = 'https://buhlib.herokuapp.com'
  end
end
