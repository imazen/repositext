# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "repositext-kramdown"
  s.version     = '0.0.1'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Nathanael Jones"]
  s.email       = ["nathanael.jones@gmail.com"]
  s.homepage    = "http://github.com/imazen/repositext-kramdown"
  s.summary     = %q{Customized parser/converter for repositext}
  s.description = ""

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency('builder')
  s.add_runtime_dependency('kramdown')
  s.add_runtime_dependency('nokogiri')
  s.add_runtime_dependency('ruby-graphviz')
  s.add_runtime_dependency('rubyzip')
  s.add_runtime_dependency('suspension')

  # Test libraries
  s.add_development_dependency('awesome_print')
  s.add_development_dependency('rake')
  s.add_development_dependency('minitest')
  s.add_development_dependency('minitest-spec-expect')
end
