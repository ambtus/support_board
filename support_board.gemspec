# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "support_board/version"

Gem::Specification.new do |s|
  s.name        = "support_board"
  s.version     = SupportBoard::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Sidra']
  s.email       = ['ambtus@gmail.com']
  s.homepage    = "http://github.com/otwcode/support_board"
  s.summary     = %q{Integrated support board}
  s.description = %q{Add a public support board to your rails application}

  s.rubyforge_project = "support_board"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "rails"

  s.add_development_dependency "cucumber-rails"
  s.add_development_dependency "capybara"
  s.add_development_dependency "pickle"
  s.add_development_dependency "factory_girl"

end
