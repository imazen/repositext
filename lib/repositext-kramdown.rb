# NOTE: None of the CLI code is required here. It's required in lib/rt/cli.rb

# TODO: look at this for configuration:
# http://brandonhilkert.com/blog/ruby-gem-configuration-patterns/
# https://news.ycombinator.com/item?id=7428051

require 'awesome_print'
require 'erb'
require 'json'
require 'kramdown/document'
require 'outcome'
require 'suspension'

require 'patch_string'

require 'kramdown/converter/graphviz'
require 'kramdown/converter/html_doc'
require 'kramdown/converter/icml'
require 'kramdown/converter/idml_story'
require 'kramdown/converter/kramdown_repositext'
require 'kramdown/converter/patch_base'
require 'kramdown/converter/plain_text'
require 'kramdown/element_rt'
require 'kramdown/mixins/adjacent_element_merger'
require 'kramdown/mixins/import_whitespace_sanitizer'
require 'kramdown/mixins/nested_ems_processor'
require 'kramdown/mixins/tmp_em_class_processor'
require 'kramdown/mixins/tree_cleaner'
require 'kramdown/mixins/whitespace_out_pusher'
require 'kramdown/parser/folio'
require 'kramdown/parser/folio/ke_context'
require 'kramdown/parser/idml'
require 'kramdown/parser/idml_story'
require 'kramdown/parser/kramdown_repositext'
require 'kramdown/patch_element'

require 'repositext/fix/adjust_merged_record_mark_positions'
require 'repositext/fix/convert_abbreviations_to_lower_case'
require 'repositext/fix/convert_folio_typographical_chars'
require 'repositext/fix/remove_underscores_inside_folio_paragraph_numbers'
