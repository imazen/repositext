require 'awesome_print'
require 'erb'
require 'find'
require 'json'
require 'kramdown'
require 'logging'
require 'nokogiri'
require 'open3'
require 'ostruct'
require 'outcome'
require 'rugged'
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
require 'repositext/constants'

# The requires are grouped by levels of dependencies, where lower groups depend on
# higher level groups.


# Dependency boundary

require 'kramdown/converter/gap_mark_tagging'
require 'kramdown/converter/graphviz'
require 'kramdown/converter/html_doc'
require 'kramdown/converter/icml'
require 'kramdown/converter/idml_story'
require 'kramdown/converter/latex_repositext'
require 'kramdown/converter/latex_repositext/document_mixin'
require 'kramdown/converter/latex_repositext/render_record_marks_mixin'
require 'kramdown/converter/latex_repositext/render_subtitle_and_gap_marks_mixin'
require 'kramdown/converter/report_misaligned_question_paragraphs'
require 'kramdown/converter/report_paragraph_classes_inventory'
require 'kramdown/converter/kramdown_repositext'
require 'kramdown/converter/patch_base'
require 'kramdown/converter/plain_text'
require 'kramdown/converter/subtitle'
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
require 'repositext/repository'
require 'repositext/utils/entity_encoder'
require 'repositext/utils/filename_part_extractor'
require 'repositext/utils/subtitle_filename_converter'
require 'repositext/validation'
require 'repositext/validation/utils/config'
require 'repositext/validation/utils/logger'
require 'repositext/validation/utils/logger_test'
require 'repositext/validation/utils/reportable'
require 'repositext/validation/utils/reporter'
require 'repositext/validation/utils/reporter_test'
require 'repositext/validation/validator'
require 'repositext/validation/validator/subtitle_import/body_text_extractor'

# Dependency boundary

require 'kramdown/converter/latex_repositext_book'
require 'kramdown/converter/latex_repositext_comprehensive'
require 'kramdown/converter/latex_repositext_plain'
require 'kramdown/converter/latex_repositext_recording'
require 'kramdown/converter/latex_repositext_translator'
require 'kramdown/converter/latex_repositext_web'
require 'kramdown/converter/subtitle_tagging'
require 'repositext/cli/config'
require 'repositext/cli/long_descriptions_for_commands'
require 'repositext/cli/patch_thor_with_rtfile'
require 'repositext/cli/rtfile_dsl'
require 'repositext/cli/utils'
require 'repositext/compare/record_id_and_paragraph_alignment'
require 'repositext/convert/latex_to_pdf'
require 'repositext/fix/adjust_gap_mark_positions'
require 'repositext/fix/adjust_merged_record_mark_positions'
require 'repositext/fix/convert_abbreviations_to_lower_case'
require 'repositext/fix/convert_folio_typographical_chars'
require 'repositext/fix/normalize_editors_notes'
require 'repositext/fix/normalize_subtitle_mark_before_gap_mark_positions'
require 'repositext/fix/remove_underscores_inside_folio_paragraph_numbers'
require 'repositext/merge/record_marks_from_folio_xml_at_into_idml_at'
require 'repositext/merge/subtitle_marks_from_subtitle_import_into_content_at'
require 'repositext/merge/titles_from_folio_roundtrip_compare_into_content_at'
require 'repositext/validation/content'
require 'repositext/validation/folio_xml_post_import'
require 'repositext/validation/folio_xml_pre_import'
require 'repositext/validation/idml_post_import'
require 'repositext/validation/idml_pre_import'
require 'repositext/validation/subtitle_post_import'
require 'repositext/validation/subtitle_pre_import'
require 'repositext/validation/test'
require 'repositext/validation/validator/folio_import_round_trip'
require 'repositext/validation/validator/idml_import_round_trip'
require 'repositext/validation/validator/idml_import_syntax'
require 'repositext/validation/validator/kramdown_syntax'
require 'repositext/validation/validator/kramdown_syntax_at'
require 'repositext/validation/validator/kramdown_syntax_pt'
require 'repositext/validation/validator/subtitle_import_consistency'
require 'repositext/validation/validator/subtitle_import_matches_subtitle_export_from_content_at'
require 'repositext/validation/validator/subtitle_mark_at_beginning_of_every_paragraph'
require 'repositext/validation/validator/subtitle_mark_counts_match'
require 'repositext/validation/validator/subtitle_mark_spacing'
require 'repositext/validation/validator/utf8_encoding'
# NOTE: Don't require the custom validator examples as they interfere with specs
# require 'repositext/validation/a_custom_example'
# require 'repositext/validation/validator/a_custom_example'

# Dependency boundary

require 'repositext/cli/commands/compare'
require 'repositext/cli/commands/convert'
require 'repositext/cli/commands/copy'
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
