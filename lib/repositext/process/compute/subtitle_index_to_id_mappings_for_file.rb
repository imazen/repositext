class Repositext
  class Process
    class Compute

      # Computes mappings fro subtitle indexes to persistent ids for a file
      # and patch.
      class SubtitleIndexToIdMappingsForFile

        # Value object wrapper for Rugged::Diff::Hunk
        class Hunk

          attr_reader :lines, :old_lines, :old_start

          # @param hunk [Rugged::Diff::Hunk]
          def self.new_from_rugged_hunk(hunk)
            new(
              hunk.old_start,
              hunk.old_lines,
              hunk.lines.map { |e|
                SubtitleIndexToIdMappingsForFile::HunkLine.new_from_rugged_line(e)
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
        # @param content_at_file [Repositext::RFile::ContentAt]
        # @param patch [Rugged::Diff::Patch]
        def self.new_from_content_at_file_and_patch(content_at_file, patch)
          new(
            compute_content_at_lines_with_subtitles(content_at_file),
            patch.hunks.map { |e|
              SubtitleIndexToIdMappingsForFile::Hunk.new_from_rugged_hunk(e)
            },
            content_at_file
          )
        end

        # Returns a data structure for all text lines in content_at_file
        # with their subtitles.
        # @param content_at_file [Repositext::RFile::ContentAt]
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
        # @param content_at_file [Repositext::RFile::ContentAt]
        def initialize(content_at_lines_with_subtitles, hunks, content_at_file)
          @content_at_lines_with_subtitles = content_at_lines_with_subtitles
          @hunks = hunks
          @content_at_file = content_at_file
        end

        # @return [Repositext::Subtitle::OperationsForFile]
        def compute
puts
puts "New file: ========================================================="
puts @content_at_file.filename
puts
          mappings_for_all_hunks = @hunks.inject([]) { |m,hunk|
            m += SubtitleIndexToIdMappingsForHunk.new(
              @content_at_lines_with_subtitles[(hunk.old_start - 1), hunk.old_lines],
              hunk
            ).compute
            m
          }

          # Assign subtitle indexes and count missing STIDs
          missing_stid_count = 0
          mappings_for_all_hunks.each_with_index { |mapping, idx|
            # indexes are 1 based
            mapping[:stIndex] = idx + 1
            missing_stid_count += 1  if 'new' == mapping[:stid]
          }

# TODO: This is a shortcut. Handle stids_inventory file properly!
          stids_inventory_file = File.open(
            '/Users/johund/development/vgr-english/data/subtitle_ids.txt',
            'r+'
          )

          new_stids = Repositext::Subtitle::IdGenerator.new(
            stids_inventory_file
          ).generate(
            missing_stid_count
          ).shuffle

          # Assign newly generated STIDs
          mappings_for_all_hunks.each { |mapping|
            if 'new' == mapping[:stid]
              mapping[:stid] = new_stids.shift
            end
          }

          Repositext::Subtitle::IndexToIdMappingsForFile.new(
            @content_at_file,
            {
              fromGitCommit: nil,
              toGitCommit: nil,
              comments: "File: #{ @content_at_file.basename }",
            },
            mappings_for_all_hunks
          )
        end

      end
    end
  end
end
