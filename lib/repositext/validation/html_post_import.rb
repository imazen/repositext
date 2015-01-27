class Repositext
  class Validation
    class HtmlPostImport < Validation

      # Specifies validations to run related to HTML import.
      def run_list
        validate_files(:input_html_files) do |path|
          Validator::Utf8Encoding.new(
            File.open(path), @logger, @reporter, @options
          ).run
        end
        validate_files(:imported_at_files) do |path|
          @options['run_options'] << 'kramdown_syntax_at-no_underscore_or_caret'
          Validator::KramdownSyntaxAt.new(
            File.open(path), @logger, @reporter, @options
          ).run
        end

        # File pairs

        # Validate that plain text in HTML files is consistent with plain text
        # in imported AT files.
        # Define proc that computes html_imported_at filename from html filename
        hiat_filename_proc = lambda { |input_filename, file_specs|
          input_filename.gsub(/\.html\z/, '.html.at')
        }
        # Run pairwise validation
        validate_file_pairs(:input_html_files, hiat_filename_proc) do |ih, hiat|
          Validator::HtmlImportConsistency.new(
            [File.open(ih), File.open(hiat)],
            @logger,
            @reporter,
            @options
          ).run
        end
      end

    end
  end
end
