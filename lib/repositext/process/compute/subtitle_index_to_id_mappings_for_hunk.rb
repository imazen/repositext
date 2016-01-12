class Repositext
  class Process
    class Compute

      # Computes mappings for subtitle indexes to ids for a hunk
      class SubtitleIndexToIdMappingsForHunk

        # @param content_at_lines_with_subtitles [Array<Hash>]
        #   {
        #     content: "the content",
        #     line_no: 42,
        #     subtitles: [<Subtitle>, ...],
        #   }
        # @param hunk [SubtitleOperationsForFile::Hunk]
        def initialize(content_at_lines_with_subtitles, hunk)
          @content_at_lines_with_subtitles = content_at_lines_with_subtitles
          @hunk = hunk
          @all_subtitles = []
        end

        # @return [Array<Subtitle::Operation>]
        def compute
          compute_hunk_mappings(
            @content_at_lines_with_subtitles,
            compute_per_origin_line_groups(@hunk)
          )
        end

      protected

        # @param hunk [SubtitleOperationsForFile::Hunk]
        # @return [Array<Hash>]
        #   [
        #     {
        #       line_origin: :addition,
        #       content: "word word word",
        #       old_linenos: [3,4,5],
        #     },
        #     ...
        #   ]
        def compute_per_origin_line_groups(hunk)
          polgs = []
          current_origin = nil
          hunk.lines.each { |line|
            if current_origin != line.line_origin
              # Add new segment
              polgs << { line_origin: line.line_origin, content: '', old_linenos: [] }
              current_origin = line.line_origin
            end
            polgs.last[:content] << line.content
            polgs.last[:old_linenos] << line.old_lineno
          }
          polgs
        end

        # Has to handle these per_origin_line_group signatures:
        # * [:deletion, :addition]
        # * [:deletion, :eof_newline_added, :addition]
        # * [:addition]
        # * [:deletion]
        # @param content_at_lines_with_subtitles [Array<Hash>]
        # @param per_origin_line_groups [Array<Hash>]
        # @return [Array<Subtitle::Operation>]
        def compute_hunk_mappings(content_at_lines_with_subtitles, per_origin_line_groups)
puts "New Hunk --------------------------------------------------------"
pp per_origin_line_groups
          reconstructed_subtitles = []
          deleted_lines_group = per_origin_line_groups.detect { |e| :deletion == e[:line_origin] }
          added_lines_group = per_origin_line_groups.detect { |e| :addition == e[:line_origin] }
          original_content = content_at_lines_with_subtitles.map{ |e|
            e[:content]
          }.join("\n") + "\n"
          hunk_subtitles = content_at_lines_with_subtitles.map { |e|
            e[:subtitles]
          }.flatten
          # validate content_at and hunk consistency
          if original_content != deleted_lines_group[:content]
            raise "Mismatch between content_at and hunk:\n#{ original_content.inspect }\n#{ deleted_lines_group[:content].inspect }"
          end

          deleted_subtitles = break_line_into_subtitles(deleted_lines_group[:content])
          added_subtitles = break_line_into_subtitles(added_lines_group[:content])

          # Compute alignment
          aligner = Compute::SubtitleOperationsForHunk::SubtitleAligner.new(
            deleted_subtitles,
            added_subtitles,
          )

puts aligner.inspect_alignment(120)

          # Compute operations
          deleted_aligned_subtitles, added_aligned_subtitles = aligner.get_optimal_alignment

          # Collect all subtitle objects for added
          deleted_aligned_subtitles.each_with_index { |deleted_st,idx|
            added_st = added_aligned_subtitles[idx]

            case (deleted_st[:content] || '').count('@')
            when 0
              st_mapping = { stid: 'new', stIndex: nil }
              st_mapping[:before] = deleted_st[:content] ? deleted_st[:content].gsub('@', '') : nil
              st_mapping[:after] = added_st[:content] ? added_st[:content].gsub('@', '') : nil
              reconstructed_subtitles << st_mapping
puts
puts "Empty deleted. Added: #{ st_mapping.inspect }"
            when 1
              st_obj = hunk_subtitles.shift
              st_mapping = { stid: st_obj.persistent_id, stIndex: nil }
              st_mapping[:before] = deleted_st[:content] ? deleted_st[:content].gsub('@', '') : nil
              st_mapping[:after] = added_st[:content] ? added_st[:content].gsub('@', '') : nil
              reconstructed_subtitles << st_mapping
puts
puts "Full deleted. Added: #{ st_mapping.inspect }"
            else
              raise "Handle this: #{ deleted_st.inspect }"
            end

          }

          reconstructed_subtitles
        end

        # @param line_contents [String]
        # @return [Array<Hash>] array of subtitle caption hashes
        def break_line_into_subtitles(line_contents)
          line_contents.split(/(?=@)/).map { |e|
            {
              content: e,
              length: e.length,
              stid: 'todo',
            }
          }
        end

      end

    end
  end
end
