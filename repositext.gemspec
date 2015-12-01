# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "repositext"
  s.version     = '0.0.1'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jo Hund", "Nathanael Jones"]
  s.email       = ["jhund@clearcove.ca"]
  s.homepage    = "http://github.com/imazen/repositext"
  s.summary     = %q{Customized parser/converter for repositext}
  s.description = ""

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency('activesupport', '~> 4.2')
  s.add_dependency('alignment')
  s.add_dependency('awesome_print')
  s.add_dependency('builder')
  s.add_dependency('caracal', '~> 1.0')
  # I would have liked to use diff_match_patch which we already use for suspension, however
  # there was no simple way to do line diffing in DMP, so I use this gem for now.
  s.add_dependency('diff-lcs')
  s.add_dependency('kramdown')
  s.add_dependency('logging')
  s.add_dependency('needleman_wunsch_aligner')
  s.add_dependency('nokogiri')
  s.add_dependency('obscenity')
  s.add_dependency('outcome')
  s.add_dependency('parallel')
  s.add_dependency('pragmatic_segmenter')
  s.add_dependency('ruby-graphviz')
  s.add_dependency('rubyzip')
  s.add_dependency('rugged')
  s.add_dependency('suspension')
  s.add_dependency('thor')
  s.add_dependency('unicode_utils')

  s.add_development_dependency('bundler', "~> 1.3")
  s.add_development_dependency('fakefs')
  s.add_development_dependency('rake')
  s.add_development_dependency('minitest')
  s.add_development_dependency('minitest-spec-expect')
  s.add_development_dependency('ruby-prof')
end
