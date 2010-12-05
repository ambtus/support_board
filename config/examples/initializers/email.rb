# Email settings
module SupportBoard
  class Application < Rails::Application
    config.action_mailer.delivery_method = :smtp
    ActionMailer::Base.default_url_options = {:host => "YOURHOSTNAME"}
    config.action_mailer.smtp_settings = {
      :address => "localhost",
      :port => 25,
    }
  end
end
