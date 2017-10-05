class Repositext
  class Cli
    # This namespace contains methods related to the `validate` command.
    module Validate

    private

      # Validates all files in /content directory
      def validate_content(options)
        options['report_file'] ||= config.compute_glob_pattern(:content_dir, :validation_report_file, '')
        # Note: make sure to insert a single record mark into all AT files
        # using `rt fix insert_record_mark_into_all_at_files`
        options['run_options'] << 'kramdown_syntax_at-all_elements_are_inside_record_mark'
        reset_validation_report(options, 'validate_content')
        input_base_dir = config.compute_base_dir(options['base-dir'] || :content_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        at_file_extension = config.compute_file_extension(options['file-extension'] || :at_extension)
        file_specs = config.compute_validation_file_specs(
          primary: [input_base_dir, input_file_selector, at_file_extension], # for reporting only
          content_at_files: [input_base_dir, input_file_selector, at_file_extension],
          repositext_files: [input_base_dir, input_file_selector, :repositext_extensions],
        )
        validation_options = {
          'config' => config,
          'content_type' => content_type,
          'is_primary_repo' => config.setting(:is_primary_repo),
          'kramdown_validation_parser_class' => config.kramdown_parser(:kramdown_validation),
          'primary_content_type_transform_params' => primary_content_type_transform_params,
          'use_new_r_file_api' => true
        }.merge(options)
        Repositext::Validation::Content.new(file_specs, validation_options).run
      end

      # Validates all files related to docx export (post)
      def validate_docx_post_export(options)
        options['report_file'] ||= config.compute_glob_pattern(
          :docx_export_dir, :validation_report_file, ''
        )
        input_base_dir = config.compute_base_dir(options['base-dir'] || :docx_export_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        docx_file_extension = config.compute_file_extension(
          options['file-extension'] || :docx_extension
        )
        file_specs = config.compute_validation_file_specs(
          primary: [input_base_dir, input_file_selector, docx_file_extension], # for reporting only
          exported_docx_files: [input_base_dir, input_file_selector, docx_file_extension],
        )

        validation_options = {
          'append_to_validation_report' => false,
          'content_type' => content_type,
          'docx_parser_class' => config.kramdown_parser(:docx),
          'kramdown_converter_method_name' => config.kramdown_converter_method(:to_at),
          'kramdown_parser_class' => config.kramdown_parser(:kramdown),
          'report_file' => config.compute_glob_pattern(
            :docx_export_dir, :validation_report_file, ''
          ),
          'use_new_r_file_api' => true
        }.merge(options)

        Repositext::Validation::DocxPostExport.new(file_specs, validation_options).run
      end

      # Validates all files related to docx import (post)
      # Runs validations on content AT files so that they can be opened from
      # console log with single click for corrections.
      def validate_docx_post_import(options)
        options['report_file'] ||= config.compute_glob_pattern(
          :docx_import_dir, :validation_report_file, ''
        )
        input_base_dir = config.compute_base_dir(options['base-dir'] || :docx_import_dir)
        content_base_dir = config.compute_base_dir(:content_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        docx_file_extension = config.compute_file_extension(
          options['file-extension'] || :docx_extension
        )
        file_specs = config.compute_validation_file_specs(
          primary: [input_base_dir, input_file_selector, docx_file_extension], # for reporting only
          docx_files: [input_base_dir, input_file_selector, docx_file_extension],
          imported_at_files: [content_base_dir, input_file_selector, :at_extension],
          imported_repositext_files: [content_base_dir, input_file_selector, :repositext_extensions],
        )

        validation_options = {
          'config' => config,
          'content_type' => content_type,
          'kramdown_converter_method_name' => config.kramdown_converter_method(:to_at),
          'kramdown_parser_class' => config.kramdown_parser(:kramdown),
          'kramdown_validation_parser_class' => config.kramdown_parser(:kramdown_validation),
          'use_new_r_file_api' => true
        }.merge(options)

        Repositext::Validation::DocxPostImport.new(file_specs, validation_options).run
      end

      # Validates all files related to docx import (pre)
      def validate_docx_pre_import(options)
        options['report_file'] ||= config.compute_glob_pattern(
          :docx_import_dir, :validation_report_file, ''
        )
        reset_validation_report(options, 'validate_docx_import')
        input_base_dir = config.compute_base_dir(options['base-dir'] || :docx_import_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        docx_file_extension = config.compute_file_extension(
          options['file-extension'] || :docx_extension
        )
        file_specs = config.compute_validation_file_specs(
          primary: [input_base_dir, input_file_selector, docx_file_extension], # for reporting only
          docx_files: [input_base_dir, input_file_selector, docx_file_extension],
        )

        validation_options = {
          'content_type' => content_type,
          'docx_parser_class' => config.kramdown_parser(:docx),
          'docx_validation_parser_class' => config.kramdown_parser(:docx_validation),
          'kramdown_converter_method_name' => config.kramdown_converter_method(:to_at),
          'kramdown_parser_class' => config.kramdown_parser(:kramdown),
          'kramdown_validation_parser_class' => config.kramdown_parser(:kramdown_validation),
        }.merge(options)

        Repositext::Validation::DocxPreImport.new(file_specs, validation_options).run
      end

      # Validates all files related to folio xml import
      def validate_folio_xml_import(options)
        options['report_file'] ||= config.compute_glob_pattern(:folio_import_dir, :validation_report_file, '')
        reset_validation_report(options, 'validate_folio_xml_import')
        input_base_dir = config.compute_base_dir(options['base-dir'] || :folio_import_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        folio_xml_sources_file_extension = config.compute_file_extension(
          options['file-extension'] || :xml_extension
        )
        file_specs = config.compute_validation_file_specs(
          primary: [input_base_dir, input_file_selector, folio_xml_sources_file_extension], # for reporting only
          folio_xml_sources: [input_base_dir, input_file_selector, folio_xml_sources_file_extension],
          imported_at_files: [input_base_dir, input_file_selector, :at_extension],
          imported_repositext_files: [input_base_dir, input_file_selector, :repositext_extensions],
        )
        validation_options = {
          'folio_xml_parser_class' => config.kramdown_parser(:folio_xml),
          'kramdown_converter_method_name' => config.kramdown_converter_method(:to_at),
          'kramdown_parser_class' => config.kramdown_parser(:kramdown),
          'kramdown_validation_parser_class' => config.kramdown_parser(:kramdown_validation)
        }.merge(options)
        if options['run_options'].include?('pre_import')
          Repositext::Validation::FolioXmlPreImport.new(file_specs, validation_options).run
        end
        if options['run_options'].include?('post_import')
          Repositext::Validation::FolioXmlPostImport.new(file_specs, validation_options).run
        end
      end

      def validate_gap_mark_tagging_import(options)
        options['report_file'] ||= config.compute_glob_pattern(
          :gap_mark_tagging_import_dir, :validation_report_file, ''
        )
        reset_validation_report(options, 'validate_gap_mark_tagging_import')
        input_base_dir = config.compute_base_dir(options['base-dir'] || :gap_mark_tagging_import_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        gap_mark_tagging_file_extension = config.compute_file_extension(
          options['file-extension'] || :txt_extension
        )
        file_specs = config.compute_validation_file_specs(
          primary: [input_base_dir, input_file_selector, gap_mark_tagging_file_extension], # for reporting only
          content_at_files: [:content_dir, input_file_selector, :at_extension],
          gap_mark_tagging_import_files: [input_base_dir, input_file_selector, gap_mark_tagging_file_extension],
          gap_mark_tagging_export_files: [:gap_mark_tagging_export_dir, input_file_selector, gap_mark_tagging_file_extension],
        )
        validation_options = {
          'kramdown_parser_class' => config.kramdown_parser(:kramdown),
          'kramdown_validation_parser_class' => config.kramdown_parser(:kramdown_validation),
        }.merge(options)
        if options['run_options'].include?('pre_import')
          Repositext::Validation::GapMarkTaggingPreImport.new(file_specs, validation_options).run
        end
        if options['run_options'].include?('post_import')
          Repositext::Validation::GapMarkTaggingPostImport.new(file_specs, validation_options).run
        end
      end

      # Validates all files related to html import
      def validate_html_import(options)
        options['report_file'] ||= config.compute_glob_pattern(
          :html_import_dir, :validation_report_file, ''
        )
        reset_validation_report(options, 'validate_html_import')
        input_base_dir = config.compute_base_dir(options['base-dir'] || :html_import_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        html_input_file_extension = config.compute_file_extension(options['file-extension'] || :html_extension)
        file_specs = config.compute_validation_file_specs(
          primary: [input_base_dir, input_file_selector, html_input_file_extension], # for reporting only
          input_html_files: [input_base_dir, input_file_selector, html_input_file_extension],
          imported_at_files: [input_base_dir, input_file_selector, :at_extension],
        )
        validation_options = {
          'kramdown_parser_class' => config.kramdown_parser(:kramdown),
          'plain_text_converter_method_name' => config.kramdown_converter_method(:to_plain_text),
          'kramdown_validation_parser_class' => config.kramdown_parser(:kramdown_validation)
        }.merge(options)
        Repositext::Validation::HtmlPostImport.new(file_specs, validation_options).run
      end

      # Validates all files related to idml import
      def validate_idml_import(options)
        options['report_file'] ||= config.compute_glob_pattern(
          :idml_import_dir, :validation_report_file, ''
        )
        reset_validation_report(options, 'validate_idml_import')
        input_base_dir = config.compute_base_dir(options['base-dir'] || :idml_import_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        idml_sources_file_extension = config.compute_file_extension(
          options['file-extension'] || :idml_extension
        )
        file_specs = config.compute_validation_file_specs(
          primary: [input_base_dir, input_file_selector, idml_sources_file_extension], # for reporting only
          idml_sources: [input_base_dir, input_file_selector, idml_sources_file_extension],
          imported_at_files: [input_base_dir, input_file_selector, :at_extension],
          imported_repositext_files: [input_base_dir, input_file_selector, :repositext_extensions],
        )
        validation_options = {
          'idml_parser_class' => config.kramdown_parser(:idml),
          'idml_validation_parser_class' => config.kramdown_parser(:idml_validation),
          'kramdown_converter_method_name' => config.kramdown_converter_method(:to_at),
          'kramdown_parser_class' => config.kramdown_parser(:kramdown),
          'kramdown_validation_parser_class' => config.kramdown_parser(:kramdown_validation),
        }.merge(options)
        if options['run_options'].include?('pre_import')
          Repositext::Validation::IdmlPreImport.new(file_specs, validation_options).run
        end
        if options['run_options'].include?('post_import')
          Repositext::Validation::IdmlPostImport.new(file_specs, validation_options).run
        end
      end

      # Validates that plain text of idml import AT is consistent with plain text of content AT
      def validate_idml_import_consistency(options)
        options['report_file'] ||= config.compute_glob_pattern(
          :idml_import_dir, :validation_report_file, ''
        )
        reset_validation_report(options, 'validate_idml_import')
        input_base_dir = config.compute_base_dir(options['base-dir'] || :idml_import_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        input_file_extension = config.compute_file_extension(
          options['file-extension'] || :at_extension
        )
        file_specs = config.compute_validation_file_specs(
          primary: [input_base_dir, input_file_selector, input_file_extension], # for reporting only
          idml_import_at_files: [input_base_dir, input_file_selector, input_file_extension],
        )
        Repositext::Validation::IdmlImportConsistency.new(file_specs, options).run
      end

      def validate_paragraph_style_consistency(options)
        options['report_file'] ||= File.join(
          config.compute_base_dir(:reports_dir),
          'validate_paragraph_style_consistency.txt'
        )
        reset_validation_report(options, 'validate_paragraph_style_consistency')
        input_base_dir = config.compute_base_dir(options['base-dir'] || :content_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        file_specs = config.compute_validation_file_specs(
          primary: [input_base_dir, input_file_selector, :at_extension], # for reporting only
          content_at_files: [input_base_dir, input_file_selector, :at_extension],
        )
        validation_options = {
          'is_primary_repo' => config.setting(:is_primary_repo),
          'kramdown_parser_class' => config.kramdown_parser(:kramdown),
          'primary_content_type_transform_params' => primary_content_type_transform_params,
          'use_new_r_file_api' => true,
          'content_type' => content_type,
        }.merge(options)
        Repositext::Validation::ParagraphStyleConsistency.new(file_specs, validation_options).run
      end

      def validate_pdf_export(options)
        options['report_file'] ||= File.join(
          config.compute_base_dir(:reports_dir),
          'validate_pdf_export.txt'
        )
        reset_validation_report(options, 'validate_pdf_export')
        input_base_dir = config.compute_base_dir(options['base-dir'] || :pdf_export_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        file_specs = config.compute_validation_file_specs(
          primary: [input_base_dir, input_file_selector, :pdf_extension], # for reporting only
          exported_pdfs: [input_base_dir, input_file_selector, :pdf_extension],
        )
        # Spawn jruby process with extract_text_from_pdf_service
        begin
          extract_text_from_pdf_service = Repositext::Services::ExtractTextFromPdf.new
          extract_text_from_pdf_service.start
          validation_options = {
            'content_type' => content_type,
            'extract_text_from_pdf_service' => extract_text_from_pdf_service,
            'pdfbox_text_extraction_options' => config.setting(:pdfbox_text_extraction_options),
          }.merge(options)
          Repositext::Validation::PdfExport.new(file_specs, validation_options).run
        ensure
          extract_text_from_pdf_service.stop
        end
      end

      def validate_rtfile(options)
        Repositext::Validation::Rtfile.new(
          config.compute_base_dir(options['base-dir'] || :content_type_dir) + 'Rtfile',
          config
        ).run
      end

      def validate_spot_sheet(options)
        options['report_file'] ||= config.compute_glob_pattern(:accepted_corrections_dir, :validation_report_file, '')
        reset_validation_report(options, 'validate_spot_sheet_reads_consistency')
        input_base_dir = config.compute_base_dir(options['base-dir'] || :accepted_corrections_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        txt_file_extension = config.compute_file_extension(options['file-extension'] || :txt_extension)
        file_specs = config.compute_validation_file_specs(
          primary: [input_base_dir, input_file_selector, txt_file_extension], # for reporting only
          accepted_corrections_files: [input_base_dir, input_file_selector, txt_file_extension],
        )
        validation_options = {
          'validate_or_merge' => options['validate_or_merge'] || 'validate',
          'content_type' => content_type,
        }.merge(options)
        Repositext::Validation::SpotSheet.new(file_specs, validation_options).run
      end

      def validate_subtitle_mark_at_beginning_of_every_paragraph(options)
        options['report_file'] ||= config.compute_glob_pattern(:content_dir, :validation_report_file, '')
        reset_validation_report(options, 'validate_subtitle_mark_at_beginning_of_every_paragraph')
        input_base_dir = config.compute_base_dir(options['base-dir'] || :content_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        at_file_extension = config.compute_file_extension(options['file-extension'] || :at_extension)
        file_specs = config.compute_validation_file_specs(
          primary: [input_base_dir, input_file_selector, at_file_extension], # for reporting only
          content_at_files: [input_base_dir, input_file_selector, at_file_extension],
        )
        validation_options = {
          'is_primary_repo' => config.setting(:is_primary_repo),
          'primary_content_type_transform_params' => primary_content_type_transform_params,
        }.merge(options)
        Repositext::Validation::SubtitleMarkAtBeginningOfEveryParagraph.new(file_specs, validation_options).run
      end

      def validate_subtitle_mark_no_significant_changes(options)
        options['report_file'] ||= config.compute_glob_pattern(:content_dir, :validation_report_file, '')
        reset_validation_report(options, 'validate_subtitle_mark_no_significant_changes')
        input_base_dir = config.compute_base_dir(options['base-dir'] || :content_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        at_file_extension = config.compute_file_extension(options['file-extension'] || :at_extension)
        file_specs = config.compute_validation_file_specs(
          primary: [input_base_dir, input_file_selector, at_file_extension], # for reporting only
          content_at_files: [input_base_dir, input_file_selector, at_file_extension],
        )
        validation_options = {
          'primary_content_type_transform_params' => primary_content_type_transform_params,
        }.merge(options)
        Repositext::Validation::SubtitleMarkNoSignificantChanges.new(file_specs, validation_options).run
      end

      def validate_subtitle_mark_spacing(options)
        options['report_file'] ||= config.compute_glob_pattern(:content_dir, :validation_report_file, '')
        reset_validation_report(options, 'validate_subtitle_mark_spacing')
        input_base_dir = config.compute_base_dir(options['base-dir'] || :content_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        at_file_extension = config.compute_file_extension(options['file-extension'] || :at_extension)
        file_specs = config.compute_validation_file_specs(
          primary: [input_base_dir, input_file_selector, at_file_extension], # for reporting only
          content_at_files: [input_base_dir, input_file_selector, at_file_extension],
        )
        validation_options = {
          'is_primary_repo' => config.setting(:is_primary_repo),
          'primary_content_type_transform_params' => primary_content_type_transform_params,
        }.merge(options)
        Repositext::Validation::SubtitleMarkSpacing.new(file_specs, validation_options).run
      end

      def validate_system_setup
        # check for fonts
        # right version of git
      end

      def validate_subtitle_import(options)
        options['report_file'] ||= config.compute_glob_pattern(
          :subtitle_import_dir, :validation_report_file, ''
        )
        reset_validation_report(options, 'validate_subtitle_import')
        input_base_dir = config.compute_base_dir(options['base-dir'] || :subtitle_import_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        subtitle_files_extension = config.compute_file_extension(
          options['file-extension'] || :txt_extension
        )
        file_specs = config.compute_validation_file_specs(
          primary: [input_base_dir, input_file_selector, subtitle_files_extension], # for reporting only
          content_at_files: [:content_dir, input_file_selector, :at_extension],
          subtitle_import_files: [input_base_dir, input_file_selector, subtitle_files_extension],
          subtitle_export_files: [:subtitle_export_dir, input_file_selector, subtitle_files_extension],
        )
        validation_options = {
          'is_primary_repo' => config.setting(:is_primary_repo),
          'kramdown_parser_class' => config.kramdown_parser(:kramdown),
          'kramdown_validation_parser_class' => config.kramdown_parser(:kramdown_validation),
          'primary_content_type_transform_params' => primary_content_type_transform_params,
          'subtitle_converter_method_name' => config.kramdown_converter_method(:to_subtitle),
          'subtitle_export_converter_method_name' => config.kramdown_converter_method(:to_subtitle),
        }.merge(options)
        if options['run_options'].include?('pre_import')
          Repositext::Validation::SubtitlePreImport.new(file_specs, validation_options).run
        end
        if options['run_options'].include?('post_import_1')
          Repositext::Validation::SubtitlePostImport1.new(file_specs, validation_options).run
        end
        if options['run_options'].include?('post_import_2')
          Repositext::Validation::SubtitlePostImport2.new(file_specs, validation_options).run
        end
      end

      def validate_subtitle_tagging_import(options)
        options['report_file'] ||= config.compute_glob_pattern(
          :subtitle_tagging_import_dir, :validation_report_file, ''
        )
        reset_validation_report(options, 'validate_subtitle_tagging_import')
        input_base_dir = config.compute_base_dir(
          options['base-dir'] || :subtitle_tagging_import_dir
        )
        input_file_selector = config.compute_file_selector(
          options['file-selector'] || :all_files
        )
        subtitle_tagging_files_extension = config.compute_file_extension(
          options['file-extension'] || :txt_extension
        )
        file_specs = config.compute_validation_file_specs(
          primary: [input_base_dir, input_file_selector, subtitle_tagging_files_extension], # for reporting only
          content_at_files: [:content_dir, input_file_selector, :at_extension],
          subtitle_import_files: [input_base_dir, input_file_selector, subtitle_tagging_files_extension],
          subtitle_export_files: [:subtitle_tagging_export_dir, input_file_selector, subtitle_tagging_files_extension],
        )
        validation_options = {
          'is_primary_repo' => config.setting(:is_primary_repo),
          'kramdown_parser_class' => config.kramdown_parser(:kramdown),
          'kramdown_validation_parser_class' => config.kramdown_parser(:kramdown_validation),
          'primary_content_type_transform_params' => primary_content_type_transform_params,
          'subtitle_converter_method_name' => config.kramdown_converter_method(:to_subtitle_tagging),
          'subtitle_export_converter_method_name' => config.kramdown_converter_method(:to_subtitle),
        }.merge(options)
        if options['run_options'].include?('pre_import')
          Repositext::Validation::SubtitlePreImport.new(file_specs, validation_options).run
        end
        if options['run_options'].include?('post_import')
          Repositext::Validation::SubtitlePostImport.new(file_specs, validation_options).run
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
      # @param options [Hash] salient keys: 'report_file' and 'append_to_validation_report'
      # @param marker [String] An id line that will be added to the top of the
      #   report, along with a time stamp.
      def reset_validation_report(options, marker)
        return true if options['append_to_validation_report']
        if options['report_file']
          # reset report
          Repositext::Validation.reset_report(options['report_file'], marker)
          @options
        end
      end

      # Returns a hash with transform params for the primary repo
      # TODO: Replace this with Rfile!!!
      def primary_content_type_transform_params
        {
          filename: nil,
          language_code_3_chars: config.setting(:language_code_3_chars),
          content_type_dir: config.base_dir(:content_type_dir),
          relative_path_to_primary_content_type: config.setting(:relative_path_to_primary_content_type),
          primary_repo_lang_code: config.setting(:primary_repo_lang_code)
        }
      end
    end
  end
end
