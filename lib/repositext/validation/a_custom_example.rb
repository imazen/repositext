class Repositext
  class Validation
    # Template for a custom validation.
    class ACustomExample < Validation

      # Specify which validations to run.
      def run_list
        # File validations
        all_plain_text_files(@file_pattern).each { |r_file|
          Validator::Utf8Encoding.new(r_file, @logger, @reporter, @options).run
        }
      end

    end
  end
end
