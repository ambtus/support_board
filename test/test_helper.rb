ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
DatabaseCleaner.strategy = :truncation

class ActiveSupport::TestCase
  # TODO when seeds are finalized, dump them to fixtures and load fixtures instead
  setup do
    load "#{Rails.root}/db/seeds.rb"
  end
  teardown do
    DatabaseCleaner.clean
  end
end

