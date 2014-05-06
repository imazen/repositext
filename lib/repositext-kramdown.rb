# NOTE: None of the CLI code is required here. It's required in lib/rt/cli.rb

# TODO: look at this for configuration:
# http://brandonhilkert.com/blog/ruby-gem-configuration-patterns/
# https://news.ycombinator.com/item?id=7428051

require 'awesome_print'
require 'erb'
require 'find'
require 'json'
require 'kramdown'
require 'logging'
require 'outcome'
require 'suspension'

require 'patch_array'
require 'patch_string'
require 'recursive_data_hash'

# The requires are grouped by levels of dependencies, where lower groups depend on
# higher level groups.

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
require 'kramdown/parser/kramdown_validation'
require 'kramdown/patch_element'
require 'repositext/validation'
require 'repositext/validation/utils/config'
require 'repositext/validation/utils/logger'
require 'repositext/validation/utils/logger_test'
require 'repositext/validation/utils/reportable'
require 'repositext/validation/utils/reporter'
require 'repositext/validation/utils/reporter_test'
require 'repositext/validation/validator'

# Dependency boundary

require 'repositext/fix/adjust_gap_mark_positions'
require 'repositext/fix/adjust_merged_record_mark_positions'
require 'repositext/fix/convert_abbreviations_to_lower_case'
require 'repositext/fix/convert_folio_typographical_chars'
require 'repositext/fix/remove_underscores_inside_folio_paragraph_numbers'
require 'repositext/merge/record_marks_from_folio_xml_at_into_idml_at'
require 'repositext/validation/content'
require 'repositext/validation/folio_xml_post_import'
require 'repositext/validation/folio_xml_pre_import'
require 'repositext/validation/idml_post_import'
require 'repositext/validation/idml_pre_import'
require 'repositext/validation/test'
require 'repositext/validation/validator/folio_import_round_trip'
require 'repositext/validation/validator/idml_import_round_trip'
require 'repositext/validation/validator/idml_import_syntax'
require 'repositext/validation/validator/kramdown_syntax'
require 'repositext/validation/validator/kramdown_syntax_at'
require 'repositext/validation/validator/kramdown_syntax_pt'
require 'repositext/validation/validator/utf8_encoding'
# NOTE: Don't require the custom validator examples as they interfere with specs
# require 'repositext/validation/a_custom_example'
# require 'repositext/validation/validator/a_custom_example'

# Dependency boundary

