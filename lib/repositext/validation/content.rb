class Repositext
  class Validation
    class Content < Validation

      # Specifies validations to run for files in the /content directory
      def run_list
        validate_files(:repositext_files) do |file_name|
          Validator::Utf8Encoding.new(file_name, @logger, @reporter, @options).run
        end
        validate_files(:at_files) do |file_name|
          Validator::KramdownSyntaxAt.new(file_name, @logger, @reporter, @options).run
          Validator::SubtitleMarkSpacing.new(file_name, @logger, @reporter, @options).run
        end
        validate_files(:pt_files) do |file_name|
          Validator::KramdownSyntaxPt.new(file_name, @logger, @reporter, @options).run
        end
      end

    end
  end
end
