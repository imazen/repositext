Repositext Kramdown
===================

A customized parser/converter for repositext.

The parser class in `lib/repositext/parser/repositext.rb` contains the
implementation of the special repositext.org parser that is based on the
kramdown parser.

If a document is parsed with it, the resulting document tree **cannot**
be converted by an un-patched converter because of special
repositext.org elements.

Installation (while in development)
-----------------------------------

Follow these steps to install repositext-kramdown:

* Install Ruby 2.0 using rbenv or rvm.
* Install the bundler gem: `gem install bundler`
* Clone the repository from github.com
* Switch into the repositext-kramdown directory: `cd repositext-kramdown`
* Install the required gems: `bundle install`

Usage
-----

Use these commands to perform conversions:

### Convert IDML files to kramdown

    bundle exec batch_import_idml_files_to_at_files '../idml_files/*'

#### File Pattern

You can use file patterns to select which files you want to convert. You can
use all features of [Ruby's Dir.glob method](http://ruby-doc.org/core-2.0.0/Dir.html#method-c-glob).

When providing a relative file pattern, the current directory will be used as
base directory.

**IMPORTANT NOTE**: When using glob patterns, it is important that you surround
the pattern with quotes. Otherwise the shell will evaluate the pattern and you
will likely only convert a single file (the first one that matches the pattern).

## Special elements

repositext-kramdown adds the following elements to kramdown:

* :gap_mark (%, span element, no content)
* :subtitle_mark (@, span element, no content)
* :record_mark (block element)

## IDML and IDML story parsers

There is an IDML file parser in `lib/repositext/parser/idml.rb` and an
IDML story file parser in `lib/repositext/parser/idml_story.rb`. The
IDML file parser is not a kramdown parser like the IDML story file
parser -- it just reads an IDML file, extracts the IDML story files and
uses the IDML story file parser to parse them.

Note that the IDML story file parser needs to be supplied not with a
whole IDML file but just with an IDML story file.

## How to run specs

To run the entire spec suite:

    bundle exec rake

or to run a single file:

    bundle exec ruby specs/kramdown/parser/idml_story/regression_spec.rb
