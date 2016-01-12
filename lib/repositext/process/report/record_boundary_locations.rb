class Repositext
  class Process
    class Report

      # Reports where record boundaries are located inside of (:nothing, :paragraph, :span)
      class RecordBoundaryLocations

        # Initialize a new report
        # @param repositext_file [RFile]
        # @param kramdown_parser [Kramdown::Parser] to parse repositext_file contents
        def initialize(repositext_file, kramdown_parser)
          raise(ArgumentError.new("Invalid repositext_file: #{ repositext_file.inspect }"))  unless repositext_file.is_a?(RFile)
          @repositext_file = repositext_file
          @kramdown_parser = kramdown_parser
        end

        # Returns an outcome with a report of record boundary locations
        # @return [Outcome] with result = { nothing: 42, paragraph: 42, span: 42 }
        def report
          subtitles = @repositext_file.subtitles
          return Outcome.new(false, nil)  if subtitles.empty?

          root, warnings = Kramdown::Parser::KramdownVgr.parse(@repositext_file.contents)
          doc = Kramdown::Document.new('', subtitles: subtitles)
          doc.root = root
          report = doc.to_report_record_boundary_locations
          comments = report.delete(:comments)
          Outcome.new(true, report, comments)
        end

      end
    end
  end
end
