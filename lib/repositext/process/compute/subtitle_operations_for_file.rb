class Repositext
  class Process
    class Compute

      # Computes subtitle operations for a file and patch.
      class SubtitleOperationsForFile

        # Value object wrapper for Rugged::Diff::Hunk
        class Hunk

          attr_reader :lines, :old_lines, :old_start

          # @param hunk [Rugged::Diff::Hunk]
          def self.new_from_rugged_hunk(hunk)
            new(
              hunk.old_start,
              hunk.old_lines,
              hunk.lines.map { |e|
                SubtitleOperationsForFile::HunkLine.new_from_rugged_line(e)
              }
            )
          end

          # @param old_start [Integer] first line of hunk
          # @param old_lines [Integer] sum of context + deleted lines in hunk
          # @param lines [Array<SubtitleOperationsForFile::HunkLine>]
          def initialize(old_start, old_lines, lines)
            @old_start = old_start
            @old_lines = old_lines
            @lines = lines
          end

        end

        # Value object wrapper for Rugged::Diff::Line
        class HunkLine

          attr_reader :content, :old_lineno, :line_origin

          # @param line [Rugged::Diff::Line]
          def self.new_from_rugged_line(line)
            new(
              line.line_origin,
              line.content.force_encoding(Encoding::UTF_8),
              line.old_lineno
            )
          end

          # @param line_origin [Symbol]
          # @param content [String]
          # @param old_lineno [Integer]
          def initialize(line_origin, content, old_lineno)
            @line_origin = line_origin
            @content = content
            @old_lineno = old_lineno
          end

        end

        # Initializes a new instance from high level objects.
        # @param content_at_file [Repositext::RFile]
        # @param patch [Rugged::Diff::Patch]
        def self.new_from_content_at_file_and_patch(content_at_file, patch)
          new(
            compute_content_at_lines_with_subtitles(content_at_file),
            patch.hunks.map { |e|
              SubtitleOperationsForFile::Hunk.new_from_rugged_hunk(e)
            },
            content_at_file
          )
        end

        # Returns a data structure for all text lines in content_at_file
        # with their subtitles.
        # @param content_at_file [Repositext::RFile]
        # @return [Array<Hash>] with keys :content, :line_no, :subtitles
        def self.compute_content_at_lines_with_subtitles(content_at_file)
          r = []
          subtitles = content_at_file.subtitles
          content_at_file.contents
                         .split("\n")
                         .each_with_index { |content_at_line, idx|
            r << {
              content: content_at_line,
              line_no: idx + 1,
              subtitles: subtitles.shift(content_at_line.count('@')),
            }
          }
          r
        end

        # @param content_at_lines_with_subtitles [Array<Hash>]
        # @param hunks [Array<SubtitleOperationsForFile::Hunk>]
        # @param content_at_file [Repositext::RFile]
        def initialize(content_at_lines_with_subtitles, hunks, content_at_file)
          @content_at_lines_with_subtitles = content_at_lines_with_subtitles
          @hunks = hunks
          @content_at_file = content_at_file
        end

        # @return [Repositext::Subtitle::OperationsForFile]
        def compute
          last_stid = 'new_file'
          hunk_index = -1
          operations_for_all_hunks = @hunks.inject([]) { |m,hunk|
            r = SubtitleOperationsForHunk.new(
              @content_at_lines_with_subtitles[(hunk.old_start - 1), hunk.old_lines],
              hunk,
              last_stid,
              hunk_index += 1
            ).compute
            last_stid = r[:last_stid]
            m += r[:subtitle_operations]
          }
          # TODO: Check if we have cross-hunk/line/para subtitle moves. They are
          # indicated by ins/dels at the end of the first and the beginning of
          # the second hunk.
          Repositext::Subtitle::OperationsForFile.new(
            @content_at_file,
            {
              comments: "File: #{ @content_at_file.basename }",
            },
            operations_for_all_hunks
          )
        end

      end
    end
  end
end
