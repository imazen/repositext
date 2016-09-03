# This file uses two FSMs for subtitles and other to extract operations.
# It works quite well, however the results are not well aligned with subtitles.
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
          @st_fsm = init_st_fsm
          @st_fsm_affected_subtitles = []
          @st_fsm_detected_operation = nil
          @st_fsm_auto_trigger_event = nil
          @other_fsm = init_other_fsm
          @other_fsm_detected_operation = nil
          @other_fsm_auto_trigger_event = nil
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
pp per_origin_line_groups
          collected_operations = []
          deleted_lines_group = per_origin_line_groups.first
          added_lines_group = per_origin_line_groups.last
          original_content = content_at_lines_with_subtitles.map{ |e|
            e[:content]
          }.join("\n") + "\n"
          hunk_subtitles = content_at_lines_with_subtitles.map { |e| e[:subtitles] }.flatten
          # validate content_at and hunk consistency
          if original_content != deleted_lines_group[:content]
            raise "Mismatch between content_at and hunk:\n#{ original_content.inspect }\n#{ deleted_lines_group[:content].inspect }"
          end
          # Create line diffs
          diff_segments = Suspension::StringComparer.compare(
            deleted_lines_group[:content],
            added_lines_group[:content],
            false,
            false
          )
# diff_segments.each { |ds|
#   puts "    - #{ ds }"
# }
          diff_segments.each do |(insdel, str)|
            diff_segment_subtitles = hunk_subtitles.shift(str.count('@'))
if [1,-1].include?(insdel) && str.count('@') > 1
  puts
  puts "check this out:"
  p diff_segments
end
# puts "  - Diff segment: #{ [insdel, str].inspect }"
            # Trigger state machine event depending on new diff segment
            # Start with strictest conditions
            if 1 == insdel
              # Addition
              if '@' == str
                trigger_fsms_event!(:add_subtitle)
              elsif str =~ REGEX_SUBTITLE_BEFORE_OTHER
                trigger_fsms_event!(:add_subtitle_before_other)
              elsif str.index('@')
                trigger_fsms_event!(:add_subtitle_and_other)
              else
                trigger_fsms_event!(:add_other)
              end
              @st_fsm_affected_subtitles += diff_segment_subtitles
            elsif -1 == insdel
              # Removal
              if '@' == str
                trigger_fsms_event!(:remove_subtitle)
              elsif str =~ REGEX_SUBTITLE_BEFORE_OTHER
                trigger_fsms_event!(:remove_subtitle_before_other)
              elsif str.index('@')
                trigger_fsms_event!(:remove_subtitle_and_other)
              else
                trigger_fsms_event!(:remove_other)
              end
              @st_fsm_affected_subtitles += diff_segment_subtitles
            elsif 0 == insdel
              # Equality
              if str =~ REGEX_SUBTITLE_BEFORE_OTHER
                trigger_fsms_event!(:equal_subtitle_before_other)
              elsif str.index('@')
                trigger_fsms_event!(:equal_subtitle_and_other)
              elsif str.index("\n")
                trigger_fsms_event!(:equal_eol)
              else
                trigger_fsms_event!(:equal_other)
              end
            else
              raise "Handle this: #{ insdel.inspect }, #{ str.inspect }"
            end

            # Check if we detected any operations
            if(st_dso = @st_fsm_detected_subtitle_operation)
              collected_operations << Subtitle::Operation.new_from_hash(
                affectedStids: @st_fsm_affected_subtitles,
                operationId: '',
                operationType: st_dso,
              )
              @st_fsm_detected_subtitle_operation = nil
            end
            if(other_dso = @other_fsm_detected_subtitle_operation)
              # We decided to ignore content changes
              # collected_operations << Subtitle::Operation.new_from_hash(
              #   affectedStids: [],
              #   operationId: '',
              #   operationType: other_dso,
              # )
              @other_fsm_detected_subtitle_operation = nil
            end

            # Check if we need to trigger any auto transitions
            if(st_ate = @st_fsm_auto_trigger_event)
              @st_fsm.trigger!(st_ate)
              @st_fsm_auto_trigger_event = nil
            end
            if(other_ate = @other_fsm_auto_trigger_event)
              @other_fsm.trigger!(other_ate)
              @other_fsm_auto_trigger_event = nil
            end
          end

          if :idle != @st_fsm.state || :idle != @other_fsm.state
            raise "Uncompleted operation analysis for hunk!"
          end

          collected_operations
        end

        # An FSM specifically to track subtitle state
        # @return [Micromachine]
        def init_st_fsm
          fsm = MicroMachine.new(:idle)

          # Define state transitions

          # Add other content, no subtitles
          fsm.when(
            :add_other,
            idle: :idle,
            poss_delete: :poss_delete,
            poss_insert: :poss_insert,
            st_added: :st_added,
            st_removed: :st_removed,
          )
          # Add exactly one subtitle
          fsm.when(
            :add_subtitle,
            idle: :st_added,
            poss_delete: :found_move_right,
            st_added: :found_split_j_st_added,
            st_removed: :found_move_right,
          )
          # Add at least one subtitle and other in no particular order
          fsm.when(
            :add_subtitle_and_other,
            idle: :st_added,
            st_added: :found_split_j_st_added,
            st_removed: :found_move_right,
          )
          # Add subtitle followed by other
          fsm.when(
            :add_subtitle_before_other,
            idle: :poss_insert,
            poss_delete: :found_move_right,
            st_added: :found_split,
            st_removed: :found_move_right,
          )
          # Equal, end of line
          fsm.when(
            :equal_eol,
            idle: :idle,
            st_added: :found_split,
            st_removed: :found_merge,
            poss_delete: :found_delete,
            poss_insert: :found_insert,
          )
          # Equal, contains no subtitles
          fsm.when(
            :equal_other,
            idle: :idle,
            poss_delete: :poss_delete,
            poss_insert: :poss_insert,
            st_added: :st_added,
            st_removed: :st_removed,
          )
          # Equal, contains at least one subtitle
          fsm.when(
            :equal_subtitle_and_other,
            idle: :idle,
            poss_delete: :found_delete,
            st_added: :found_split,
            st_removed: :found_merge,
          )
          # Equal, starts with subtitle, followed by other
          fsm.when(
            :equal_subtitle_before_other,
            idle: :idle,
            poss_delete: :found_delete,
            poss_insert: :found_insert,
            st_added: :found_split,
            st_removed: :found_merge,
          )
          # Explicit transitions
          fsm.when(
            :go_to_poss_delete,
            found_delete_j_poss_delete: :poss_delete,
          )
          fsm.when(
            :go_to_st_added,
            found_split_j_st_added: :st_added,
          )
          fsm.when(
            :go_to_st_removed,
            found_merge_j_st_removed: :st_removed,
          )
          # Remove only other content, no subtitles
          fsm.when(
            :remove_other,
            idle: :idle,
            poss_delete: :poss_delete,
            poss_insert: :poss_insert,
            st_added: :st_added,
            st_removed: :st_removed,
          )
          # Remove exactly one subtitle
          fsm.when(
            :remove_subtitle,
            idle: :st_removed,
            poss_insert: :found_move_left,
            st_added: :found_move_left,
            st_removed: :found_merge_j_st_removed,
          )
          # Remove at least one subtitle and other in no particular order
          fsm.when(
            :remove_subtitle_and_other,
            idle: :st_removed,
            poss_delete: :found_delete_j_poss_delete,
            st_added: :found_move_left,
            st_removed: :found_merge_j_st_removed,
          )
          # Remove subtitle followed by other
          fsm.when(
            :remove_subtitle_before_other,
            idle: :poss_delete,
            poss_delete: :found_delete_j_poss_delete,
            poss_insert: :found_move_left,
            st_added: :found_move_left,
          )
          # Used for auto transitions
          fsm.when(
            :reset,
            found_delete: :idle,
            found_insert: :idle,
            found_merge: :idle,
            found_move_left: :idle,
            found_move_right: :idle,
            found_split: :idle,
          )

          # Define callbacks at state entry
          fsm.on(:found_delete) do
            @st_fsm_detected_subtitle_operation = :delete
            @st_fsm_auto_trigger_event = :reset
          end

          fsm.on(:found_delete_j_poss_delete) do
            @st_fsm_detected_subtitle_operation = :delete
            @st_fsm_auto_trigger_event = :go_to_poss_delete
          end

          fsm.on(:found_insert) do
            @st_fsm_detected_subtitle_operation = :insert
            @st_fsm_auto_trigger_event = :reset
          end

          fsm.on(:found_merge) do
            @st_fsm_detected_subtitle_operation = :merge
            @st_fsm_auto_trigger_event = :reset
          end

          fsm.on(:found_merge_j_st_removed) do
            @st_fsm_detected_subtitle_operation = :merge
            @st_fsm_auto_trigger_event = :go_to_st_removed
          end

          fsm.on(:found_move_left) do
            @st_fsm_detected_subtitle_operation = :moveLeft
            @st_fsm_auto_trigger_event = :reset
          end

          fsm.on(:found_move_right) do
            @st_fsm_detected_subtitle_operation = :moveRight
            @st_fsm_auto_trigger_event = :reset
          end

          fsm.on(:found_split) do
            @st_fsm_detected_subtitle_operation = :split
            @st_fsm_auto_trigger_event = :reset
          end

          fsm.on(:found_split_j_st_added) do
            @st_fsm_detected_subtitle_operation = :split
            @st_fsm_auto_trigger_event = :go_to_st_added
          end

          fsm.on(:idle) do
            @st_fsm_affected_subtitles = []
            @st_fsm_detected_subtitle_operation = nil
          end

# fsm.on(:any) do
#   puts "    st: #{ fsm.state }"
#   if(dso = @st_fsm_detected_subtitle_operation)
#     puts "    Operation: #{ dso }"
#   end
# end

          fsm
        end

        # An FSM specifically to track other state
        # @return [Micromachine]
        def init_other_fsm
          fsm = MicroMachine.new(:idle)

          # Define state transitions

          # Add other content, no subtitles
          fsm.when(
            :add_other,
            idle: :other_added,
            other_removed: :found_content_change,
          )
          # Add exactly one subtitle
          fsm.when(
            :add_subtitle,
            idle: :idle,
            other_removed: :found_content_change,
          )
          # Add at least one subtitle and other in no particular order
          fsm.when(
            :add_subtitle_and_other,
            idle: :other_added,
            other_removed: :found_content_change,
          )
          # Add subtitle followed by other
          fsm.when(
            :add_subtitle_before_other,
            idle: :other_added,
            other_removed: :found_content_change,
          )
          # Equal, end of line
          fsm.when(
            :equal_eol,
            idle: :idle,
            other_added: :found_content_change,
            other_removed: :found_content_change,
          )
          # Equal, contains no subtitles
          fsm.when(
            :equal_other,
            idle: :idle,
            other_added: :found_content_change,
            other_removed: :found_content_change,
          )
          # Equal, contains at least one subtitle
          fsm.when(
            :equal_subtitle_and_other,
            idle: :idle,
            other_added: :found_content_change,
            other_removed: :found_content_change,
          )
          # Equal, starts with subtitle, followed by other
          fsm.when(
            :equal_subtitle_before_other,
            idle: :idle,
            other_added: :found_content_change,
            other_removed: :found_content_change,
          )
          # Remove only other content, no subtitles
          fsm.when(
            :remove_other,
            idle: :other_removed,
            other_added: :found_content_change,
            other_removed: :other_removed,
          )
          # Remove exactly one subtitle
          fsm.when(
            :remove_subtitle,
            idle: :idle,
          )
          # Remove at least one subtitle and other in no particular order
          fsm.when(
            :remove_subtitle_and_other,
            idle: :other_removed,
            other_added: :found_content_change,
          )
          # Remove subtitle followed by other
          fsm.when(
            :remove_subtitle_before_other,
            idle: :other_removed,
          )
          # Used for auto transitions
          fsm.when(
            :reset,
            found_content_change: :idle,
          )

          # Define callbacks at state entry
          fsm.on(:found_content_change) do
            @other_fsm_detected_subtitle_operation = :contentChange
            @other_fsm_auto_trigger_event = :reset
          end

# fsm.on(:any) do
#   puts "    other: #{ fsm.state }"
#   if(dso = @other_fsm_detected_subtitle_operation)
#     puts "    Operation: #{ dso }"
#   end
# end

          fsm
        end

        def trigger_fsms_event!(event)
# puts "    evt: #{ event }"
          @st_fsm.trigger!(event)
          @other_fsm.trigger!(event)
        end

      end

    end
  end
end
