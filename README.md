## Customized parser/converter for repositext

The parser class in `lib/repositext/parser.rb` contains the
implementation of the special repositext.org parser that is based on the
kramdown parser.

If a document is parsed with it, the resulting document tree **cannot**
be converted by an un-patched converter because of special
repositext.org elements.

A patch for the HTML converter can be loaded by requiring
`lib/repositext/kramdown_adaptions.rb`.

The binary `bin/repositext` sets up everything and converts the input
text to HTML.

## Special elements

* :line_synchro_marker (span element, no content)
* :work_synchro_marker (span element, no content)
* :subdoc (block element)

## TODO

* If sub-document IDs can start with a number, the IAL parser needs to
  be adapted due to a recent change in the kramdown library (the change
  is not released yet).

## How to run specs

    rake
