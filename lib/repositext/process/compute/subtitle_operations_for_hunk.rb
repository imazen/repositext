class Repositext
  class Process
    class Compute

      # Computes subtitle operations for a hunk
      class SubtitleOperationsForHunk

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
          @fsm = init_fsm
          @fsm_finalize_subtitle_operation = false
          @fsm_trigger_auto_event = nil
          @affected_subtitles = []
        end

        # @return [Array<Subtitle::Operation>]
        def compute
          # TODO: We may want to sort :addition and :deletion for consistency
          per_origin_line_groups = compute_per_origin_line_groups(@hunk)
          hunk_line_origin_signature = per_origin_line_groups.map { |e|
            e[:line_origin]
          }
          case hunk_line_origin_signature
          when [:deletion, :addition]
            compute_hunk_operations_for_deletion_addition(
              @content_at_lines_with_subtitles,
              per_origin_line_groups
            )
          when [:deletion, :eof_newline_added, :addition]
            # Ignore for now
            []
          when [:addition]
            # Ignore for now
            []
          when [:deletion]
            # Ignore for now
            []
          else
            raise "Handle this: #{ hunk.inspect }"
          end
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

        # @param content_at_lines_with_subtitles [Array<Hash>]
        # @param per_origin_line_groups [Array<Hash>]
        # @return [Array<Subtitle::Operation>]
        def compute_hunk_operations_for_deletion_addition(content_at_lines_with_subtitles, per_origin_line_groups)
puts "New Hunk --------------------------------------------------------"
pp per_origin_line_groups
          collected_operations = []
          deleted_lines_group = per_origin_line_groups.first
          added_lines_group = per_origin_line_groups.last
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
          aligner = SubtitleAligner.new(
            deleted_subtitles,
            added_subtitles,
          )
puts aligner.inspect_alignment(140)

          # Compute operations
          deleted_aligned_subtitles, added_aligned_subtitles = aligner.get_optimal_alignment

          # Compute some attrs and stats for further analysis
          deleted_aligned_subtitles.each_with_index { |deleted_st,idx|
            added_st = added_aligned_subtitles[idx]

            case (deleted_st[:content] || '').count('@')
            when 0
              deleted_st[:subtitles] = []
            when 1
              st_obj = hunk_subtitles.shift
              st_obj.tmp_attrs[:before] = deleted_st[:content].gsub('@', '')  if deleted_st[:content]
              st_obj.tmp_attrs[:after] = added_st[:content].gsub('@', '')  if added_st[:content]
              deleted_st[:subtitles] = [st_obj]
            else
              raise "Handle this: #{ deleted_st.inspect }"
            end

            deleted_sim_text = (deleted_st[:content] || '').gsub('@', ' ')
            added_sim_text = (added_st[:content] || '').gsub('@', ' ')
            deleted_st[:sim_left] = compute_aligned_similarity(
              deleted_sim_text || '',
              added_sim_text || '',
              :left
            )
            deleted_st[:sim_right] = compute_aligned_similarity(
              deleted_sim_text || '',
              added_sim_text || '',
              :right
            )
            deleted_st[:sim_abs] = JaccardSimilarityComputer.compute(
              deleted_sim_text || '',
              added_sim_text || '',
              false
            )
            deleted_st[:alignment] = compute_subtitle_pair_alignment(
              deleted_st,
              added_st
            )
            deleted_st[:weight] = compute_subtitle_pair_weight(
              deleted_st,
              added_st
            )
puts "align: #{ deleted_st[:alignment] }, weight: #{ deleted_st[:weight] }"
          }

          # Compute operations
          idx = 0
          prev_del_st = nil
          prev_add_st = nil
          while(idx < deleted_aligned_subtitles.length) do
            deleted_st = deleted_aligned_subtitles[idx]
            added_st = added_aligned_subtitles[idx]

            @fsm.trigger!(deleted_st[:alignment])

            if :idle != @fsm.state
              @affected_subtitles += (deleted_st[:subtitles] || [])
            end

            # Finalize started operations that require lookahead
            if(
              (next_del_st = deleted_aligned_subtitles[idx+1]).nil? ||
              [:left, :left_and_right].include?(next_del_st[:alignment])
            )
              case @fsm.state
              when :poss_ins_del
                @fsm.trigger!(:finalize_ins_del)
              when :poss_split_merge
                @fsm.trigger!(:finalize_split_merge)
              when :in_compound
                @fsm.trigger!(:finalize_compound)
              else
                # Nothing to do
              end
            end

            # Check if we can finalize an operation
            case @fsm_finalize_subtitle_operation
            when :ins_del
              if :added == deleted_st[:weight]
                # Last added is longer, insert
                collected_operations << Subtitle::Operation.new_from_hash(
                  affectedStids: @affected_subtitles,
                  operationId: '',
                  operationType: :insert,
                )
              else
                collected_operations << Subtitle::Operation.new_from_hash(
                  affectedStids: @affected_subtitles,
                  operationId: '',
                  operationType: :delete,
                )
              end
            when :move
              if :added == deleted_st[:weight]
                # Last added is longer, move to left
                collected_operations << Subtitle::Operation.new_from_hash(
                  affectedStids: @affected_subtitles,
                  operationId: '',
                  operationType: :moveLeft,
                )
              else
                collected_operations << Subtitle::Operation.new_from_hash(
                  affectedStids: @affected_subtitles,
                  operationId: '',
                  operationType: :moveRight,
                )
              end
            when :split_merge
              if [prev_del_st[:type], deleted_st[:type]].include?(:gap)
                # Deleted contains gap, split
                new_subtitle_obj = ::Repositext::Subtitle.new(
                  persistent_id: 'new',
                  tmp_attrs: {
                    before: nil,
                    after: added_st[:content].gsub('@', ''),
                  }
                )
                collected_operations << Subtitle::Operation.new_from_hash(
                  affectedStids: @affected_subtitles + [new_subtitle_obj],
                  operationId: '',
                  operationType: :split,
                )
              else
                collected_operations << Subtitle::Operation.new_from_hash(
                  affectedStids: @affected_subtitles,
                  operationId: '',
                  operationType: :merge,
                )
              end
            when :compount
            when false
              # Nothing to do
            else
              puts "Handle this! #{ @fsm_finalize_subtitle_operation }"
            end

            if @fsm_finalize_subtitle_operation
              @fsm_finalize_subtitle_operation = false
              @affected_subtitles = []
            end

            # Check if we need to trigger an auto event
            if(tae = @fsm_trigger_auto_event)
              @fsm.trigger!(tae)
              @fsm_trigger_auto_event = nil
            end

            prev_del_st = deleted_st
            prev_add_st = added_st
            idx += 1
          end

          if :idle != @fsm.state
            raise "Uncompleted operation analysis for hunk!"
          end

          collected_operations
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

        # deleted <-> right
        def compute_subtitle_pair_alignment(d_st, a_st)
          if [d_st[:type], a_st[:type]].include?(:gap)
            # check for gap first, so that we can assume presence of content below.
            :gap
          elsif d_st[:content].strip == a_st[:content].strip
            :left_and_right
          elsif 1.0 == d_st[:sim_left]
            :left
          elsif 1.0 == d_st[:sim_right]
            :right
          else
            :unaligned
          end
        end

        # deleted <-> right
        def compute_subtitle_pair_weight(d_st, a_st)
          if d_st[:length] == a_st[:length]
            :even
          elsif (d_st[:length] || 0) > (a_st[:length] || 0)
            :deleted
          elsif (d_st[:length] || 0) < (a_st[:length] || 0)
            :added
          end
        end

        def compute_aligned_similarity(a, b, alignment)
          a = a.gsub('@', ' ').strip
          b = b.gsub('@', ' ').strip
          max_len = [a.length, b.length].min
          return 0  if 0 == max_len
          case alignment
          when :left
            a[0, max_len] == b[0, max_len] ? 1.0 : 0
          when :right
            a[-max_len..-1] == b[-max_len..-1] ? 1.0 : 0
          else
            raise "Handle this: #{ alignment.inspect }"
          end
        end

        # An FSM to track operations state
        # @return [Micromachine]
        def init_fsm
          fsm = MicroMachine.new(:idle)

          # Define state transitions

          # A gap
          fsm.when(
            :gap,
            idle: :poss_ins_del,
            in_compound: :in_compound,
            poss_split_merge: :in_compound,
            started: :poss_split_merge,
          )
          # Explicit transitions
          fsm.when(
            :finalize_ins_del,
            poss_ins_del: :found_ins_del,
          )
          fsm.when(
            :finalize_split_merge,
            poss_split_merge: :found_split_merge,
          )
          fsm.when(
            :finalize_compound,
            in_compound: :finalized_compound,
          )
          # Left aligned pair
          fsm.when(
            :left,
            idle: :started,
          )
          # Identical pair
          fsm.when(
            :left_and_right,
            idle: :idle,
          )
          # Right aligned pair
          fsm.when(
            :right,
            in_compound: :finalized_compound,
            started: :found_move,
            poss_split_merge: :finalized_compound,
            poss_split_merge_multi_moves: :found_split_merge_multi_moves,
          )
          # Not aligned
          fsm.when(
            :unaligned,
            started: :in_compound,
            in_compound: :in_compound,
            poss_split_merge: :in_compound,
          )
          # Back to idle
          fsm.when(
            :reset,
            found_ins_del: :idle,
            found_move: :idle,
            found_split_merge: :idle,
            finalized_compound: :idle,
          )

          # Define callbacks at state entry
          fsm.on(:found_ins_del) do
            @fsm_finalize_subtitle_operation = :ins_del
            @fsm_trigger_auto_event = :reset
          end

          fsm.on(:found_move) do
            @fsm_finalize_subtitle_operation = :move
            @fsm_trigger_auto_event = :reset
          end

          fsm.on(:found_split_merge) do
            @fsm_finalize_subtitle_operation = :split_merge
            @fsm_trigger_auto_event = :reset
          end

          fsm.on(:finalized_compound) do
            @fsm_finalize_subtitle_operation = :compound
            @fsm_trigger_auto_event = :reset
          end

          fsm
        end

      end

    end
  end
end
