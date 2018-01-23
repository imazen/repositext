class Repositext
  class Validation
    # Validation to run after an HTML import.
    class HtmlPostImport < Validation

      # Specifies validations to run related to HTML import.
      def run_list
        config = @options['config']
        validate_files(:input_html_files) do |html_file|
          Validator::Utf8Encoding.new(
            html_file, @logger, @reporter, @options
          ).run
        end
        validate_files(:imported_at_files) do |content_at_file|
          @options['run_options'] << 'kramdown_syntax_at-no_underscore_or_caret'
          Validator::KramdownSyntaxAt.new(
            content_at_file,
            @logger,
            @reporter,
            @options.merge(
              "validator_invalid_gap_mark_regex" => config.setting(:validator_invalid_gap_mark_regex),
              "validator_invalid_subtitle_mark_regex" => config.setting(:validator_invalid_subtitle_mark_regex)
            )
          ).run
        end

        # File pairs

        # Validate that plain text in HTML files is consistent with plain text
        # in imported AT files.
        # Define proc that computes html_imported_at filename from html filename
        hiat_file_proc = lambda { |html_file|
          r = RFile::ContentAt.new(
            '_',
            html_file.language,
            html_file.filename.sub(/\.html\z/, '.html.at'),
            html_file.content_type
          )
          r.reload_contents!
          r
        }
        # Run pairwise validation
        validate_file_pairs(:input_html_files, hiat_file_proc) do |ih, hi_at|
          Validator::HtmlImportConsistency.new(
            [ih, hi_at],
            @logger,
            @reporter,
            @options
          ).run
        end
      end

    end
  end
end
