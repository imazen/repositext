class Repositext
  class Cli
    module Validate

    private

      # Validates all files in /content directory
      def validate_content(options)
        options['report_file'] ||= config.compute_glob_pattern(
          'content_dir/validation_report_file'
        )
        reset_validation_report(options, 'validate_content')
        file_specs = config.compute_validation_file_specs(
          primary: 'content_dir/all_files', # for reporting only
          at_files: 'content_dir/at_files',
          pt_files: 'content_dir/pt_files',
          repositext_files: 'content_dir/repositext_files'
        )
        Repositext::Validation::Content.new(
          file_specs,
          {
            'kramdown_validation_parser_class' => config.kramdown_parser(:kramdown_validation)
          }.merge(options)
        ).run
      end

      # Validates all files related to folio xml import
      def validate_folio_xml_import(options)
        options['report_file'] ||= config.compute_glob_pattern(
          'import_folio_xml_dir/validation_report_file'
        )
        reset_validation_report(options, 'validate_folio_xml_import')
        file_specs = config.compute_validation_file_specs(
          primary: 'import_folio_xml_dir/all_files', # for reporting only
          folio_xml_sources: options['input'] || 'import_folio_xml_dir/xml_files',
          imported_at_files: 'import_folio_xml_dir/at_files',
          imported_repositext_files: 'import_folio_xml_dir/repositext_files',
        )
        validation_options = {
          'folio_xml_parser_class' => config.kramdown_parser(:folio_xml),
          'kramdown_converter_method_name' => config.kramdown_converter_method(:to_at),
          'kramdown_parser_class' => config.kramdown_parser(:kramdown),
          'kramdown_validation_parser_class' => config.kramdown_parser(:kramdown_validation)
        }.merge(options)
        if options['run_options'].include?('pre_import')
          Repositext::Validation::FolioXmlPreImport.new(
            file_specs,
            validation_options
          ).run
        end
        if options['run_options'].include?('post_import')
          Repositext::Validation::FolioXmlPostImport.new(
            file_specs,
            validation_options
          ).run
        end
      end

      # Validates all files related to idml import
      def validate_idml_import(options)
        options['report_file'] ||= config.compute_glob_pattern(
          'import_idml_dir/validation_report_file'
        )
        reset_validation_report(options, 'validate_idml_import')
        file_specs = config.compute_validation_file_specs(
          primary: 'import_idml_dir/all_files', # for reporting only
          idml_sources: options['input'] || 'import_idml_dir/idml_files',
          imported_at_files: 'import_idml_dir/at_files',
          imported_repositext_files: 'import_idml_dir/repositext_files',
        )
        validation_options = {
          'idml_parser_class' => config.kramdown_parser(:idml),
          'idml_validation_parser_class' => config.kramdown_parser(:idml_validation),
          'kramdown_converter_method_name' => config.kramdown_converter_method(:to_at),
          'kramdown_parser_class' => config.kramdown_parser(:kramdown),
          'kramdown_validation_parser_class' => config.kramdown_parser(:kramdown_validation),
        }.merge(options)
        if options['run_options'].include?('pre_import')
          Repositext::Validation::IdmlPreImport.new(
            file_specs,
            validation_options
          ).run
        end
        if options['run_options'].include?('post_import')
          Repositext::Validation::IdmlPostImport.new(
            file_specs,
            validation_options
          ).run
        end
      end

      # Used for automated testing
      def validate_test(options)
        puts 'validate_test'
      end

      # ----------------------------------------------------------
      # Helper methods
      # ----------------------------------------------------------

      # Resets the validation report located at options['report_file'].
      # Validations by default append to the report file so that results of
      # earlier validations are not overwritten by those of later ones.
      # @param[Hash] salient keys: 'report_file' and 'append_to_validation_report'
      # @param[String] marker. An id line that will be added to the top of the
      #    report, along with a time stamp.
      def reset_validation_report(options, marker)
        return true if options['append_to_validation_report']
        if options['report_file']
          # reset report
          Repositext::Validation.reset_report(options['report_file'], marker)
          @options
        end
      end

    end
  end
end
