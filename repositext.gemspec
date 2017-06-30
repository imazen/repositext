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

  s.add_dependency('activesupport', '~> 5.1.2')
  s.add_dependency('alignment') # from github
  s.add_dependency('amatch', '~> 0.3.1')
  s.add_dependency('awesome_print', '~> 1.8.0')
  s.add_dependency('builder', '~> 3.2.3')
  s.add_dependency('caracal', '~> 1.0.12') # To export docx
  # I would have liked to use diff_match_patch which we already use for suspension, however
  # there was no simple way to do line diffing in DMP, so I use this gem for now.
  s.add_dependency('diff-lcs', '~> 1.3')
  s.add_dependency('dotenv', '~> 2.2.1')
  s.add_dependency('kramdown') # from local repo
  s.add_dependency('logging', '~> 2.2.2')
  s.add_dependency('micromachine', '~> 2.0.0')
  s.add_dependency('multi_ruby_runner', '~> 1.0.2')
  s.add_dependency('needleman_wunsch_aligner', '~> 1.1.1')
  s.add_dependency('nokogiri', '~> 1.8.0')
  s.add_dependency('os', '~> 1.0.0')
  s.add_dependency('outcome', '~> 1.0.1')
  s.add_dependency('parallel', '~> 1.11.2')
  s.add_dependency('pragmatic_segmenter', '~> 0.3.15')
  s.add_dependency('rainbow', '~> 2.2.2')
  s.add_dependency('ruby-graphviz', '~> 1.2.3')
  s.add_dependency('rubyzip', '~> 1.2.1')
  s.add_dependency('rugged', '~> 0.25.1.1')
  s.add_dependency('suspension', '1.0.2') # from local repo
  s.add_dependency('thor', '~> 0.19.4')
  s.add_dependency('unicode_utils', '~> 1.4.0')

  s.add_development_dependency('bundler', '~> 1.3')
  s.add_development_dependency('fakefs')
  s.add_development_dependency('rake')
  s.add_development_dependency('minitest')
  s.add_development_dependency('minitest-spec-expect')
  s.add_development_dependency('ruby-prof')
end
