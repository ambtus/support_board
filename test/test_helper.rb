ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
DatabaseCleaner.strategy = :truncation

class ActiveSupport::TestCase
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures = false
  set_fixture_class :roles_users => nil
  fixtures :all
  setup do
    User.current_user = nil
  end
end

