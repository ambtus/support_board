class Setup < Thor

  desc "config", "copy configuration files"
  method_options :force => :boolean
  def config
    Dir["config/examples/config/*"].each do |example|
      new = "config/#{File.basename(example)}"
      if File.exist?(new) && !options[:force]
        puts "Skipping #{new} because it already exists"
      else
        puts "Copying #{new}"
        FileUtils.cp(example, new)
      end
    end
    Dir["config/examples/initializers/*"].each do |example|
      new = "config/initializers/#{File.basename(example)}"
      if File.exist?(new) && !options[:force]
        puts "Skipping #{new} because it already exists"
      else
        puts "Copying #{new}"
        FileUtils.cp(example, new)
      end
    end
  end

end
