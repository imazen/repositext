class Repositext
  class Cli
    module Import

    private

      # Import DOCX and merge into master
      def import_docx(options)
        # TODO: implement this
      end

      # Import FOLIO XML and merge into master
      def import_folio_xml(options)
        # FOLIO specific operations
        convert_folio_xml_to_at(options)
        fix_folio_typographical_chars(options)

        # shared operations
        merge_record_marks_from_folio_xml_at_into_idml_at(options)
        fix_adjust_merged_record_mark_positions(options)
        move_staging_to_master(options)
      end

      # Import IDML and merge into master
      def import_idml(options)
        # IDML specific operations
        convert_idml_to_at(options)

        # shared operations
        merge_record_marks_from_folio_xml_at_into_idml_at(options)
        fix_adjust_merged_record_mark_positions(options)
        move_staging_to_master(options)
      end

      def import_test(options)
        # dummy method for testing
        puts 'import_test'
      end

    end
  end
end
