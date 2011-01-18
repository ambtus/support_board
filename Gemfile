source 'http://rubygems.org'

# rails gems
gem 'bundler', '~>1.0.0'
gem 'rails', '3.0.3'

gem 'mysql2'

gem 'authlogic',
  :git     => 'git://github.com/odorcicd/authlogic.git',
  :branch  => 'rails3',
  :require => 'authlogic'
gem 'permit_yo'

gem "escape_utils"

gem "workflow"

group :development do
  # enable debugging with "rails server -u" or "rails server --debugger"
  gem 'ruby-debug19', :require => 'ruby-debug'
end

group :test do
  gem 'autotest-rails'
  gem 'cucumber-rails'
  gem 'database_cleaner'
  gem 'capybara'
  gem 'pickle'
  gem 'factory_girl'
  gem 'launchy'
end

