class Repositext
  class Validation
    class SubtitleMarkAtBeginningOfEveryParagraph < Validation

      # Specifies validations to run for files in the /content directory
      def run_list
        validate_files(:content_at_files) do |path|
          if @options['is_primary_repo']
            Validator::SubtitleMarkAtBeginningOfEveryParagraph.new(
              File.open(path), @logger, @reporter, @options.merge(:content_type => :content)
            ).run
          end
        end
      end
    end
  end
end
