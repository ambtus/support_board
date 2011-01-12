require 'database_cleaner'
DatabaseCleaner.strategy = :truncation
# clean the database before starting
DatabaseCleaner.clean
