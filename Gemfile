source 'https://rubygems.org'

gemspec

# Until we have released suspension, I need to put it here so that it can be
# installed from a :path (gemspec doesn't handle this).
# Once it is released and stable, we can remove this entry and rely on the
# dependency in .gemspec.
gem 'suspension', path: '../suspension'

# While we may have pending patches, use local kramdown with patches.
# NOTE: You need to check out the 'gemfile' branch to make it work.
gem 'kramdown', path: '../kramdown'

gem 'alignment', git: 'https://github.com/bloomrain/alignment'

# These are for gem development only
gem 'yard', git: 'https://github.com/lsegal/yard.git'
