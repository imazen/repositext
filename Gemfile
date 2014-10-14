source 'https://rubygems.org'

gemspec

# Until we have released suspension, I need to put it here so that it can be
# installed from a :path (gemspec doesn't handle this).
# Once it is released and stable, we can remove this entry and rely on the
# dependency in .gemspec.
gem 'suspension', :path => '../suspension'

# While we may have pending patches, use local kramdown with patches.
# NOTE: You need to check out the 'gemfile' branch to make it work.
gem 'kramdown', :path => '../kramdown'

# We need to use rubyzip master until the next version after 1.1.0 is released
# To address an issue when unzipping from a String
gem 'rubyzip', :git => 'https://github.com/rubyzip/rubyzip.git',
               :ref => '09ac194540e03a99419a7f48cbba92b8a9069b39'
