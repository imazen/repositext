# This file uses a single combined FSM. The FSM ended up being too complex.
class Repositext
  class Process
    class Compute

      # Computes subtitle operations for a hunk
      class SubtitleOperationsForHunk

        # @param content_at_lines_with_subtitles [Array<Hash>]
        # @param hunk [SubtitleOperationsForFile::Hunk]
        def initialize(content_at_lines_with_subtitles, hunk)
          @content_at_lines_with_subtitles = content_at_lines_with_subtitles
          @hunk = hunk
          @fsm = init_fsm
          @fsm_detected_subtitle_operation = nil
          @fsm_auto_trigger_event = nil
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

        REGEX_SUBTITLE_BEFORE_OTHER = /\A\s?@.+/

        # @param content_at_lines_with_subtitles [Array<Hash>]
        # @param per_origin_line_groups [Array<Hash>]
        # @return [Array<Subtitle::Operation>]
        def compute_hunk_operations_for_deletion_addition(content_at_lines_with_subtitles, per_origin_line_groups)
puts "New Hunk --------------------------------------------------------"
          collected_operations = []
          deleted_lines_group = per_origin_line_groups.first
          added_lines_group = per_origin_line_groups.last
          original_content = content_at_lines_with_subtitles.map{ |e| e[:content] }.join("\n") + "\n"
          # validate content_at and hunk consistency
          if original_content != deleted_lines_group[:content]
            raise "Mismatch between content_at and hunk:\n#{ original_content.inspect }\n#{ deleted_lines_group[:content].inspect }"
          end
          # Create line diffs
          diff_segments = Suspension::DiffAlgorithm.new.call(
            deleted_lines_group[:content],
            added_lines_group[:content]
          )
diff_segments.each { |ds|
  puts "    - #{ ds }"
}
          diff_segments.each do |(insdel, str)|
puts "  - Diff segment: #{ [insdel, str].inspect }"
            # Trigger state machine event depending on new diff segment
            # Start with strictest conditions
            if 1 == insdel
              # Addition
              if '@' == str
                @fsm.trigger!(:add_subtitle)
              elsif str =~ REGEX_SUBTITLE_BEFORE_OTHER
                @fsm.trigger!(:add_subtitle_before_other)
              elsif str.index('@')
                @fsm.trigger!(:add_subtitle_and_other)
              else
                @fsm.trigger!(:add_other)
              end
            elsif -1 == insdel
              # Removal
              if '@' == str
                @fsm.trigger!(:remove_subtitle)
              elsif str =~ REGEX_SUBTITLE_BEFORE_OTHER
                @fsm.trigger!(:remove_subtitle_before_other)
              elsif str.index('@')
                @fsm.trigger!(:remove_subtitle_and_other)
              else
                @fsm.trigger!(:remove_other)
              end
            elsif 0 == insdel
              # Equality
              if str =~ REGEX_SUBTITLE_BEFORE_OTHER
                @fsm.trigger!(:equal_subtitle_before_other)
              elsif str.index('@')
                @fsm.trigger!(:equal_with_subtitle)
              elsif str.index("\n")
                @fsm.trigger!(:equal_eol)
              else
                @fsm.trigger!(:equal_other)
              end
            else
              raise "Handle this: #{ insdel.inspect }, #{ str.inspect }"
            end

            # Check if we detected a subtitle operation
            if(dso = @fsm_detected_subtitle_operation)
              collected_operations << Subtitle::Operation.new_from_hash(
                affectedStids: [],
                operationId: '',
                operationType: dso,
              )
              @fsm_detected_subtitle_operation = nil
            end
            # Check if we need to trigger an auto transition
            if(ate = @fsm_auto_trigger_event)
              @fsm.trigger!(ate)
              @fsm_auto_trigger_event = nil
            end
          end

          if :idle != @fsm.state
            raise "Uncompleted operation analysis for hunk!"
          end

          collected_operations
        end

        # @return [Micromachine] a state machine to process subtitle operations
        def init_fsm
          fsm = MicroMachine.new(:idle)

          # Define state transitions

          # Add other content, no subtitles
          fsm.when(
            :add_other,
            idle: :other_added,
            other_removed: :found_content_change,
            poss_move_left: :found_split_j_other_added,
            st_removed: :found_merge_j_other_added,
          )
          # Add exactly one subtitle
          fsm.when(
            :add_subtitle,
            idle: :st_added,
            poss_move_left: :found_split_j_st_added,
            poss_move_right: :found_move_right,
          )
          # Add subtitle followed by other
          fsm.when(
            :add_subtitle_before_other,
            idle: :poss_insert,
          )
          # Add at least one subtitle and other in no particular order
          fsm.when(
            :add_subtitle_and_other,
            other_removed: :found_content_change_j_st_added,
            idle: :st_added,
          )
          # Equal, end of line
          fsm.when(
            :equal_eol,
            idle: :idle,
            other_added: :found_content_change,
            other_removed: :found_content_change,
            poss_delete: :found_delete,
            poss_insert: :found_insert,
            st_added: :found_split,
            st_removed: :found_merge,
          )
          # Equal, contains no subtitles
          fsm.when(
            :equal_other,
            idle: :idle,
            other_added: :found_content_change,
            other_removed: :found_content_change,
            poss_delete: :found_delete,
            poss_insert: :found_insert,
            st_added: :poss_move_left,
            st_removed: :poss_move_right,
          )
          # Equal, contains at least one subtitle
          fsm.when(
            :equal_with_subtitle,
            idle: :idle,
            other_added: :found_content_change,
            other_removed: :found_content_change,
            st_added: :found_split,
            st_removed: :found_merge,
          )
          # Equal, starts with subtitle, followed by other
          fsm.when(
            :equal_subtitle_before_other,
            idle: :idle,
            other_added: :found_content_change,
            other_removed: :found_content_change,
            poss_delete: :found_delete,
            poss_insert: :found_insert,
            poss_move_left: :found_move_left,
            poss_move_right: :found_move_right,
          )
          # Joined transitions
          fsm.when(
            :go_to_other_added,
            found_split_j_other_added: :other_added,
            found_merge_j_other_added: :other_added,
          )
          fsm.when(
            :go_to_other_removed,
            found_merge_j_other_removed: :other_removed,
          )
          fsm.when(
            :go_to_st_added,
            found_content_change_j_st_added: :st_added,
            found_split_j_st_added: :st_added,
          )
          fsm.when(
            :go_to_st_removed,
            found_merge_j_st_removed: :st_removed,
          )
          # Remove only other content, no subtitles
          fsm.when(
            :remove_other,
            idle: :other_removed,
            other_added: :found_content_change,
            poss_move_right: :found_merge_j_other_removed,
          )
          # Remove exactly one subtitle
          fsm.when(
            :remove_subtitle,
            idle: :st_removed,
            poss_move_left: :found_move_left,
            poss_move_right: :found_merge_j_st_removed,
          )
          # Remove at least one subtitle and other in no particular order
          fsm.when(
            :remove_subtitle_and_other,
            idle: :st_removed,
            poss_move_right: :found_merge_j_st_removed,
          )
          # Remove subtitle followed by other
          fsm.when(
            :remove_subtitle_before_other,
            idle: :poss_delete,
          )
          # Used for auto transitions
          fsm.when(
            :reset,
            found_content_change: :idle,
            found_delete: :idle,
            found_insert: :idle,
            found_merge: :idle,
            found_move_left: :idle,
            found_move_right: :idle,
            found_split: :idle,
          )

          # Define callbacks at state entry
          fsm.on(:found_content_change) do
            @fsm_detected_subtitle_operation = :contentChange
            @fsm_auto_trigger_event = :reset
          end

          fsm.on(:found_content_change_j_st_added) do
            @fsm_detected_subtitle_operation = :contentChange
            @fsm_auto_trigger_event = :go_to_st_added
          end

          fsm.on(:found_delete) do
            @fsm_detected_subtitle_operation = :delete
            @fsm_auto_trigger_event = :reset
          end

          fsm.on(:found_insert) do
            @fsm_detected_subtitle_operation = :insert
            @fsm_auto_trigger_event = :reset
          end

          fsm.on(:found_merge) do
            @fsm_detected_subtitle_operation = :merge
            @fsm_auto_trigger_event = :reset
          end

          fsm.on(:found_merge_j_other_added) do
            @fsm_detected_subtitle_operation = :merge
            @fsm_auto_trigger_event = :go_to_other_added
          end

          fsm.on(:found_merge_j_other_removed) do
            @fsm_detected_subtitle_operation = :merge
            @fsm_auto_trigger_event = :go_to_other_removed
          end

          fsm.on(:found_merge_j_st_removed) do
            @fsm_detected_subtitle_operation = :merge
            @fsm_auto_trigger_event = :go_to_st_removed
          end

          fsm.on(:found_move_left) do
            @fsm_detected_subtitle_operation = :moveLeft
            @fsm_auto_trigger_event = :reset
          end

          fsm.on(:found_move_right) do
            @fsm_detected_subtitle_operation = :moveRight
            @fsm_auto_trigger_event = :reset
          end

          fsm.on(:found_split) do
            @fsm_detected_subtitle_operation = :split
            @fsm_auto_trigger_event = :reset
          end

          fsm.on(:found_split_j_other_added) do
            @fsm_detected_subtitle_operation = :split
            @fsm_auto_trigger_event = :go_to_other_added
          end

          fsm.on(:found_split_j_st_added) do
            @fsm_detected_subtitle_operation = :split
            @fsm_auto_trigger_event = :go_to_st_added
          end

          fsm.on(:idle) do
            @fsm_detected_subtitle_operation = nil
          end

fsm.on(:any) do
  puts ['    ', fsm.state, ' ', @fsm_detected_subtitle_operation].compact.join
end

          fsm
        end

      end

    end
  end
end
