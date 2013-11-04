## Customized parser/converter for repositext

The parser class in `lib/repositext/parser/repositext.rb` contains the
implementation of the special repositext.org parser that is based on the
kramdown parser.

If a document is parsed with it, the resulting document tree **cannot**
be converted by an un-patched converter because of special
repositext.org elements.

A patch for the HTML converter can be loaded by requiring
`lib/repositext/kramdown_adaptions.rb`.

The binary `bin/repositext` sets up everything and converts the input
text to HTML.

### Special elements

* :gap_mark (%, span element, no content)
* :subtitle_mark (@, span element, no content)
* :record_mark (block element)

### TODO (at least)

* If sub-document IDs can start with a number, the IAL parser needs to
  be adapted due to a recent change in the kramdown library (the change
  is not released yet).


## IDML and IDML story parsers

There is an IDML file parser in `lib/repositext/parser/idml.rb` and an
IDML story file parser in `lib/repositext/parser/idml_story.rb`. The
IDML file parser is not a kramdown parser like the IDML story file
parser -- it just reads an IDML file, extracts the IDML story files and
uses the IDML story file parser to parse them.

Note that the IDML story file parser needs to be supplied not with a
whole IDML file but just with an IDML story file.

### Elements that are removed during IDML import

vgrspecific

* HyperlinkTextDestination (bookmarks) in XML
* any CharStyleRange elements that contain whitespace only. We preserve the
  whitespace as Text elements, but not the char_style.

### How to run specs

To run the entire spec suite:

    bundle exec rake

or to run a single file:

    bundle exec ruby specs/kramdown/parser/idml_story/regression_spec.rb
