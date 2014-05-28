require 'awesome_print'
require 'erb'
require 'find'
require 'json'
require 'kramdown'
require 'logging'
require 'nokogiri'
require 'ostruct'
require 'outcome'
require 'suspension'
require 'thor'
require 'zip'

# Establish namespace and class inheritance before we require nested classes
# Otherwise we get a subclass mismatch error because Cli is initialized as
# standalone class (not inheriting from Thor)
class Repositext
  class Cli < Thor
  end
end

require 'patches/array'
require 'patches/nokogiri_xml_node'
require 'patches/string'
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
require 'repositext/utils/subtitle_tagging_filename_converter'
require 'repositext/validation'
require 'repositext/validation/utils/config'
require 'repositext/validation/utils/logger'
require 'repositext/validation/utils/logger_test'
require 'repositext/validation/utils/reportable'
require 'repositext/validation/utils/reporter'
require 'repositext/validation/utils/reporter_test'
require 'repositext/validation/validator'

# Dependency boundary

require 'repositext/cli/config'
require 'repositext/cli/long_descriptions_for_commands'
require 'repositext/cli/patch_thor_with_rtfile'
require 'repositext/cli/rtfile_dsl'
require 'repositext/cli/utils'
require 'repositext/compare/record_id_and_paragraph_alignment'
require 'repositext/fix/adjust_gap_mark_positions'
require 'repositext/fix/adjust_merged_record_mark_positions'
require 'repositext/fix/convert_abbreviations_to_lower_case'
require 'repositext/fix/convert_folio_typographical_chars'
require 'repositext/fix/normalize_editors_notes'
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

require 'repositext/cli/commands/compare'
require 'repositext/cli/commands/convert'
require 'repositext/cli/commands/fix'
require 'repositext/cli/commands/init'
require 'repositext/cli/commands/merge'
require 'repositext/cli/commands/move'
require 'repositext/cli/commands/report'
require 'repositext/cli/commands/sync'
require 'repositext/cli/commands/validate'

# Dependency boundary

require 'repositext/cli/commands/export'
require 'repositext/cli/commands/import'

# Dependency boundary

require 'repositext/cli'
