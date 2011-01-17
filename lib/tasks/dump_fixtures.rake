require 'find'

namespace :db do
  namespace :fixtures do
    desc 'Dumps all models into fixtures.'
    task :dump => :environment do
      models = []
      Find.find(RAILS_ROOT + '/app/models') do |path|
        unless File.directory?(path) then models << path.match(/(\w+).rb/)[1] end
      end

      puts "Found models: " + models.join(', ')

      models.each do |m|
        next if m == "user_session"
        begin
          puts "Dumping model: " + m
          model_file = RAILS_ROOT + '/test/fixtures/' + m.pluralize + '.yml'
          File.delete(model_file) if File.exists?(model_file)

          model = m.camelize.constantize
          entries = model.find(:all, :order => 'id ASC')
          hash = {}
          entries.each do |entry|
            hash["#{m}_#{entry.id}"] = entry.attributes
          end

          File.open(model_file, 'w') { |f| f.write(hash.to_yaml) }

        rescue
          puts "  problem with #{m}"
        end
      end
      puts "update roles_users.yml manually"
    end
  end
end
