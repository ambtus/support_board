Cucumber::Rails::World.use_transactional_fixtures

Fixtures.reset_cache
fixtures_folder = File.join(Rails.root, 'test', 'fixtures')
fixtures = Dir[File.join(fixtures_folder, '*.yml')].map {|f| File.basename(f, '.yml') }
Fixtures.create_fixtures(fixtures_folder, fixtures)
