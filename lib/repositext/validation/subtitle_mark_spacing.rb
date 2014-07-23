class Repositext
  class Validation
    class SubtitleMarkSpacing < Validation

      # Validates that subtitle_marks are spaced correctly in content AT
      def run_list
        # Validate subtitle_mark spacing
        validate_files(:content_at_files) do |filename|
          Validator::SubtitleMarkSpacing.new(filename, @logger, @reporter, @options).run
        end
      end

    end
  end
end
