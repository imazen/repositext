class Repositext
  class Validation
    class ACustomExample < Validation

      # Specify which validations to run.
      def run_list
        # File validations
        all_plain_text_files(@file_pattern).each { |path|
          Validator::Utf8Encoding.new(File.open(path), @logger, @reporter, @options).run
        }
      end

    end
  end
end
