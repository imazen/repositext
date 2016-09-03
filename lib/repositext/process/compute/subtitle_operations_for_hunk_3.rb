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
          @fsm_trigger_auto_event = nil
          reset_operations_group!
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

          # Compute attrs for all subtitle pairs
          deleted_aligned_subtitles.each_with_index { |deleted_st,idx|
            added_st = added_aligned_subtitles[idx]

            case (deleted_st[:content] || '').count('@')
            when 0
              deleted_st[:subtitle_object] = nil
            when 1
              st_obj = hunk_subtitles.shift
              st_obj.tmp_attrs[:before] = deleted_st[:content].gsub('@', '')  if deleted_st[:content]
              st_obj.tmp_attrs[:after] = added_st[:content].gsub('@', '')  if added_st[:content]
              deleted_st[:subtitle_object] = st_obj
            else
              raise "Handle this: #{ deleted_st.inspect }"
            end

            deleted_sim_text = (deleted_st[:content] || '').gsub('@', ' ').downcase
            added_sim_text = (added_st[:content] || '').gsub('@', ' ').downcase
            deleted_st[:sim_left] = JaccardSimilarityComputer.compute(
              deleted_sim_text,
              added_sim_text,
              true,
              :left
            )
            # deleted_st[:sim_left] = compute_aligned_similarity(
            #   deleted_sim_text || '',
            #   added_sim_text || '',
            #   :left_aligned
            # )
            deleted_st[:sim_right] = JaccardSimilarityComputer.compute(
              deleted_sim_text,
              added_sim_text,
              true,
              :right
            )
            # deleted_st[:sim_right] = compute_aligned_similarity(
            #   deleted_sim_text || '',
            #   added_sim_text || '',
            #   :right_aligned
            # )
            deleted_st[:sim_abs] = JaccardSimilarityComputer.compute(
              deleted_sim_text,
              added_sim_text,
              false
            )
            deleted_st[:subtitle_pair_type] = compute_subtitle_pair_type(
              deleted_st,
              added_st
            )
            deleted_st[:weight] = compute_subtitle_pair_weight(
              deleted_st,
              added_st
            )

#p deleted_st
puts [:subtitle_pair_type, :sim_abs, :sim_left, :sim_right].inject({}) { |m,e| m[e] = deleted_st[e]; m }

          }

          # Reset state vars
          prev_del_st = nil
          prev_add_st = nil
          reset_operations_group!

          # Iterate over all subtitle pairs and compute operation_groups
          deleted_aligned_subtitles.each_with_index { |deleted_st, idx|
            added_st = added_aligned_subtitles[idx]

            @operations_group_subtitle_pair_types << deleted_st[:subtitle_pair_type]
            @operations_group_subtitles << deleted_st[:subtitle_object]

            @fsm.trigger!(deleted_st[:subtitle_pair_type])

            # Finalize operations_group based on lookahead to next subtitle pair
            if(
              (next_del_st = deleted_aligned_subtitles[idx+1]).nil? ||
              [:left_aligned, :identical].include?(next_del_st[:subtitle_pair_type])
            )
              case @fsm.state
              when :in_compound
                @fsm.trigger!(:complete_compound)
              when :poss_ins_del
                @fsm.trigger!(:complete_ins_del)
              when :poss_split_merge
                @fsm.trigger!(:complete_split_merge)
              when :started
                @fsm.trigger!(:complete_content_change)
              else
                # Nothing to do
              end
            end

            # Check if an operations_group has been completed
            case @operations_group_detected_type
            when :content_change
              # No operations to record
            when :ins_del
# TODO: check if there may be multiple inserts or deletes (multiple gaps in a row)
              if :added == deleted_st[:weight]
                # Last added is longer, insert
                collected_operations << Subtitle::Operation.new_from_hash(
                  affectedStids: @operations_group_subtitles,
                  operationId: '',
                  operationType: :insert,
                )
              else
                collected_operations << Subtitle::Operation.new_from_hash(
                  affectedStids: @operations_group_subtitles,
                  operationId: '',
                  operationType: :delete,
                )
              end
            when :move
              if :added == deleted_st[:weight]
                # Last added is longer, move to left
                collected_operations << Subtitle::Operation.new_from_hash(
                  affectedStids: @operations_group_subtitles,
                  operationId: '',
                  operationType: :moveLeft,
                )
              else
                collected_operations << Subtitle::Operation.new_from_hash(
                  affectedStids: @operations_group_subtitles,
                  operationId: '',
                  operationType: :moveRight,
                )
              end
            when :split_merge
# TODO: check if there may be multiple inserts or deletes (multiple gaps in a row)
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
                  affectedStids: @operations_group_subtitles + [new_subtitle_obj],
                  operationId: '',
                  operationType: :split,
                )
              else
                collected_operations << Subtitle::Operation.new_from_hash(
                  affectedStids: @operations_group_subtitles,
                  operationId: '',
                  operationType: :merge,
                )
              end
            when :compound
            when nil, :identical
              # No operations to record
            else
              puts "Handle this! #{ @operations_group_detected_type.inspect }"
            end

            if @operations_group_detected_type
              reset_operations_group!
            end

            # Check if we need to trigger an auto event
            if(tae = @fsm_trigger_auto_event)
              @fsm.trigger!(tae)
              @fsm_trigger_auto_event = nil
            end

            prev_del_st = deleted_st
            prev_add_st = added_st
          }

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

        def compute_subtitle_pair_type(d_st, a_st)
          if [d_st[:type], a_st[:type]].include?(:gap)
            # check for gap first, so that we can assume presence of content below.
            :gap
          elsif d_st[:sim_abs].first > 0.9 and d_st[:sim_abs].last > 0.9
            # or d_st[:content] == a_st[:content].strip.downcase ||
            :identical
          elsif d_st[:sim_left].first > 0.9 and d_st[:sim_left].last > 0.9
            :left_aligned
          elsif d_st[:sim_right].first > 0.9 and d_st[:sim_right].last > 0.9
            :right_aligned
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
          a = a.gsub('@', ' ').strip.downcase
          b = b.gsub('@', ' ').strip.downcase
          JaccardSimilarityComputer.comput
          max_len = [a.length, b.length].min
          return 0  if 0 == max_len
          case alignment
          when :left_aligned
            a[0, max_len] == b[0, max_len] ? 1.0 : 0
          when :right_aligned
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

          # Explicit transitions
          fsm.when(
            :complete_compound,
            in_compound: :compound_completed,
          )
          fsm.when(
            :complete_content_change,
            started: :content_change_completed,
          )
          fsm.when(
            :complete_ins_del,
            poss_ins_del: :ins_del_completed,
          )
          fsm.when(
            :complete_split_merge,
            poss_split_merge: :split_merge_completed,
          )
          # A gap
          fsm.when(
            :gap,
            idle: :poss_ins_del,
            in_compound: :in_compound,
            poss_ins_del: :poss_ins_del,
            poss_split_merge: :poss_split_merge,
            started: :poss_split_merge,
          )
          # Identical pair
          fsm.when(
            :identical,
            idle: :identical_completed,
          )
          # Left aligned pair
          fsm.when(
            :left_aligned,
            idle: :started,
          )
          # Right aligned pair
          fsm.when(
            :right_aligned,
            idle: :content_change_completed,
            in_compound: :compound_completed,
            poss_ins_del: :split_merge_completed,
            poss_split_merge: :compound_completed,
            started: :move_completed,
          )
          # Not aligned
          fsm.when(
            :unaligned,
            idle: :started,
            in_compound: :in_compound,
            poss_ins_del: :in_compound,
            poss_split_merge: :in_compound,
            started: :in_compound,
          )
          # Back to idle
          fsm.when(
            :reset,
            compound_completed: :idle,
            content_change_completed: :idle,
            identical_completed: :idle,
            ins_del_completed: :idle,
            move_completed: :idle,
            split_merge_completed: :idle,
          )

          # Define callbacks at state entry
          fsm.on(:compound_completed) do
            @operations_group_detected_type = :compound
            @fsm_trigger_auto_event = :reset
          end

          fsm.on(:content_change_completed) do
            @operations_group_detected_type = :content_change
            @fsm_trigger_auto_event = :reset
          end

          fsm.on(:identical_completed) do
            @operations_group_detected_type = :identical
            @fsm_trigger_auto_event = :reset
          end

          fsm.on(:ins_del_completed) do
            @operations_group_detected_type = :ins_del
            @fsm_trigger_auto_event = :reset
          end

          fsm.on(:move_completed) do
            @operations_group_detected_type = :move
            @fsm_trigger_auto_event = :reset
          end

          fsm.on(:split_merge_completed) do
            @operations_group_detected_type = :split_merge
            @fsm_trigger_auto_event = :reset
          end

          fsm.on(:reset) do
            reset_operations_group!
          end

          fsm
        end

        # Resets state for the operations_group
        def reset_operations_group!
          @operations_group_detected_type = nil
          @operations_group_subtitle_pair_types = []
          @operations_group_subtitles = []
        end

      end

    end
  end
end
