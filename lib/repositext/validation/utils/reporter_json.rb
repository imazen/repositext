class Repositext
  class Validation

    # This Reporter collects data during validation and once the validation is
    # complete, it prints the data as JSON to $stdout so it can be consumed
    # by the calling process.
    class ReporterJson < Reporter

      attr_reader :errors, :warnings, :stats

      VALIDATION_JSON_OUTPUT_MARKER = "**** REPOSITEXT_VALIDATION_JSON_DATA_"
      VALIDATION_JSON_OUTPUT_START_MARKER = VALIDATION_JSON_OUTPUT_MARKER + "START ****"
      VALIDATION_JSON_OUTPUT_END_MARKER = VALIDATION_JSON_OUTPUT_MARKER + "END ****"

      # Prints report to $stderr as JSON
      # @param marker [String] to identify this validation. Typically the validation class name
      # @param _report_file_path [String, nil] not used.
      def write(marker, _report_file_path)
        r = {
          summary: {
            validation: marker,
            errors_count: @errors.count,
            stats_count: @stats.count,
            warnings_count: @warnings.count,
          },
          details: group_reportables_by_class,
        }
        r = JSON.generate(r, JSON_FORMATTING_OPTIONS)
        $stderr.puts(VALIDATION_JSON_OUTPUT_START_MARKER)
        $stderr.puts(r)
        $stderr.puts(VALIDATION_JSON_OUTPUT_END_MARKER)
      end

    end
  end
end
