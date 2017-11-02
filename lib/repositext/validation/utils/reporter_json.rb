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

      # Parses the console output generated in #write method to JSON.
      # This method is called by the calling process for converting console output
      # to a Ruby data structure.
      # @param console_output [String] std_error captured by calling process
      # @return [Array<Hash>] An array of Hashes, one for each Reported block
      #   surrounded by JSON output markers.
      def self.parse_console_output(console_output)
        start_marker_rx = Regexp.new(Regexp.escape(VALIDATION_JSON_OUTPUT_START_MARKER))
        end_marker_rx = Regexp.new(Regexp.escape(VALIDATION_JSON_OUTPUT_END_MARKER))
        json_blocks = []
        inside_json_block = false

        s = StringScanner.new(console_output)
        while !s.eos? do
          if !inside_json_block
            if s.skip_until(start_marker_rx)
              # We found and consumed start of JSON block
              inside_json_block = true
            else
              # No further start of JSON block found
              s.terminate
            end
          else
            # We're inside a JSON block, consume it
            if (json_block = s.scan_until(/(?=#{ end_marker_rx })/))
              json_blocks << json_block
              s.skip(end_marker_rx) # consume the end marker
              inside_json_block = false
            else
              raise "No matching end marker found!"
            end
          end
        end
        json_blocks.map { |e| JSON.parse(e) }
      end

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
