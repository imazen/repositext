class Repositext
  class Validation
    # Validation to make sure that subtitle marks are spaced correctly.
    class SubtitleMarkSpacing < Validation

      # Specifies validations to run for files in the /content directory
      def run_list
        validate_files(:content_at_files) do |content_at_file|
          if @options['is_primary_repo']
            Validator::SubtitleMarkSpacing.new(
              content_at_file, @logger, @reporter, @options.merge(:content_type => :content)
            ).run
          end
        end
      end
    end
  end
end
