class Repositext
  class Process
    class Report

      # Reports where record boundaries are located inside of (:nothing, :paragraph, :span)
      class RecordBoundaryLocations

        # Initialize a new report
        # @param content_file [RFile::Content]
        # @param kramdown_parser [Kramdown::Parser] to parse content_file contents
        def initialize(content_file, kramdown_parser)
          raise(ArgumentError.new("Invalid content_file: #{ content_file.inspect }"))  unless content_file.is_a?(RFile::Content)
          @content_file = content_file
          @kramdown_parser = kramdown_parser
        end

        # Returns an outcome with a report of record boundary locations
        # @return [Outcome] with result = { nothing: 42, paragraph: 42, span: 42 }
        def report
          subtitles = @content_file.subtitles
          return Outcome.new(false, nil)  if subtitles.empty?

          root, _warnings = Kramdown::Parser::KramdownVgr.parse(@content_file.contents)
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
