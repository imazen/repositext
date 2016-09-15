class Repositext
  class Process
    class Compute
      class SubtitleOperationsForFile
        class OperationsExtractor

          # @param aligned_subtitle_pairs [Array<AlignedSubtitlePair>]
          # @param file_date_code [String]
          def initialize(aligned_subtitle_pairs, file_date_code)
            @aligned_subtitle_pairs = aligned_subtitle_pairs
            @file_date_code = file_date_code
          end

          # Takes all the file's aligned_subtitle_pairs, and extracts subtitle
          # operations.
          # @param aligned_subtitle_pairs [Array<AlignedSubtitlePair>]
          # @return [Array<Subtitle::Operation>]
          def extract
            init_context

            until @current_asp.nil? do
              process_current_asp
              advance_to_next_asp
            end

            @ops_in_file
          end

          def init_context
            @current_asp_index = 0
            @file_operation_index = 0
            @ops_in_file = []
            @prev_stid = 'new_file'

            @prev_asp = nil
            @current_asp = @aligned_subtitle_pairs[0]
            @next_asp = @aligned_subtitle_pairs[1]
            @next_but_one_asp = @aligned_subtitle_pairs[2]

            reset_current_capture_group
          end

          def process_current_asp

            curr = @current_asp

            @asp_group_cumulative_content_change += curr[:content_length_change]
            @asp_group_cumulative_content_length_to += curr[:to][:content].length

            if debug
              puts "P (#{ @file_date_code })"  if curr[:first_in_para]
              puts " - #{ curr[:type] }"
              just_method = case curr[:type]
              when :right_aligned
                :rjust
              when :left_aligned, :fully_aligned
                :ljust
              when :unaligned, :st_added, :st_removed
                :center
              else
                raise "Handle this: #{ curr[:type] }"
              end
              para_boundaries_reporter = ->(st_attrs) {
                [
                  (st_attrs[:first_in_para] ? 'first_ip' : nil),
                  (st_attrs[:last_in_para] ? 'last_ip' : nil)
                ].compact.join(', ')
              }
              puts "   From: #{ curr[:from][:content].strip.send(just_method, 130) }   #{ para_boundaries_reporter.call(curr[:from]).ljust(17) } rid:#{ curr[:from][:record_id] || 'N/A' }"
              # puts "         #{ curr[:from][:content_sim].send(just_method, 130) }"
              puts "   To:   #{ curr[:to][:content].strip.send(just_method, 130) }   #{ para_boundaries_reporter.call(curr[:to]).ljust(17) }"
              # puts "         #{ curr[:to][:content_sim].send(just_method, 130) }"
              puts([
                "   ",
                "clc:#{ curr[:content_length_change] } ",
                "ccc:#{ @asp_group_cumulative_content_change } ",
                "sl:#{ curr[:sim_left] } ",
                "sa:#{ curr[:sim_abs] } ",
                "sr:#{ curr[:sim_right] } ",
                "reps: #{ curr[:has_repetitions] }"
              ].join)
            end

            case @prev_right_edge
            when :aligned
              # The right edge of the previous ASP is aligned:
              # Start a new capture group.
              case curr[:type]
              when :fully_aligned
                # Current ASP is self contained: Not a subtitle operation.
                if curr[:from][:content] == curr[:to][:content]
                  capture_op(:no_op)
                else
                  capture_op(:content_change)
                end
                reset_current_capture_group
              when :left_aligned, :unaligned
                # Current ASP is left aligned, starting a new capture group
                if strong_linkage_with_following_asps?
                  # Current ASP is connected to next.
                  @prev_right_edge = :unaligned
                else
                  # Self contained, not a subtitle operation
                  capture_op(:content_change)
                  reset_current_capture_group
                end
              when :right_aligned
                # Current ASP is self contained: Not a subtitle operation.
                capture_op(:content_change)
                reset_current_capture_group
              when :st_added
                # Added subtitle, not connected to previous: insert.
                capture_op(:insert)
                if strong_linkage_with_following_asps?
                  @prev_right_edge = :unaligned
                else
                  reset_current_capture_group
                end
              when :st_removed
                # Removed subtitle, not connected to previous: delete.
                capture_op(:delete)
                if strong_linkage_with_following_asps?
                  @prev_right_edge = :unaligned
                else
                  reset_current_capture_group
                end
              else
                raise "Handle this! #{ curr.inspect }"
              end

            when :unaligned
              # The right edge of the previous ASP is not aligned:
              # Continue capture group.
              case curr[:type]
              when :fully_aligned, :left_aligned
                raise "Should never get here! #{ curr.inspect }"
              when :right_aligned
                # It's a move, determine direction
                capture_op(compute_move_direction)
                reset_current_capture_group
              when :st_added
                if :st_added == @prev_asp[:type] && :insert == @ops_in_group.last.operationType
                  # This is a subsequent :insert
                  capture_op(:insert)
                else
                  # It's a split
                  capture_op(:split)
                end
                if strong_linkage_with_following_asps?
                  @prev_right_edge = :unaligned
                else
                  reset_current_capture_group
                end
              when :st_removed
                if :st_removed == @prev_asp[:type] && :delete == @ops_in_group.last.operationType
                  # This is a subsequent :delete
                  capture_op(:delete)
                else
                  # It's a merge
                  capture_op(:merge)
                end
                if strong_linkage_with_following_asps?
                  @prev_right_edge = :unaligned
                else
                  reset_current_capture_group
                end
              when :unaligned
                capture_op(compute_move_direction)
                if strong_linkage_with_following_asps?
                  @prev_right_edge = :unaligned
                else
                  reset_current_capture_group
                end
              else
                raise "Handle this! #{ curr.inspect }"
              end
            else
              raise "Handle this! #{ @prev_right_edge }"
            end

            puts "P"  if debug && curr[:last_in_para]
          end

          def advance_to_next_asp
            @current_asp_index += 1

            @prev_asp = @current_asp
            @current_asp = @aligned_subtitle_pairs[@current_asp_index]
            @next_asp = @aligned_subtitle_pairs[@current_asp_index + 1]
            @next_but_one_asp = @aligned_subtitle_pairs[@current_asp_index + 2]

            @prev_stid = @prev_asp[:subtitle_object].persistent_id
          end

          def reset_current_capture_group
            @prev_right_edge = :aligned
            @asp_group_cumulative_content_change = 0
            @asp_group_cumulative_content_length_to = 0
            @ops_in_group = []
          end

          # Computes strength of linkage between @current_asp and @next_asp
          # @return [Boolean]
          def strong_linkage_with_following_asps?
            cur = @current_asp
            nxt = @next_asp
            nbo = @next_but_one_asp

            # Current_asp is the last in file
            return false  if nxt.nil?

            # Previous one was linked to next_but_one, so this one is connected, too
            return true  if cur[:linked_to_next]

            # Next_asp has clear left boundary
            return false  if [:fully_aligned, :left_aligned].include?(nxt[:type])

            cur_contains_number_sequence = (
              cur[:to][:content] =~ ComputeSubtitleAttrs::NUMBER_SEQUENCE_REGEX ||
              cur[:from][:content] =~ ComputeSubtitleAttrs::NUMBER_SEQUENCE_REGEX
            )
            overlap_threshold = cur_contains_number_sequence ? 0.9 : 0.7

            if [:right_aligned, :unaligned].include?(nxt[:type])
              if(
                @asp_group_cumulative_content_change > 10 &&
                (
                  @asp_group_cumulative_content_change + nxt[:content_length_change]
                ) < 3
              ) || (
                StringComputations.overlap(
                  cur[:to][:content_sim],
                  nxt[:from][:content_sim],
                  overlap_threshold
                ) > 0 ||
                StringComputations.overlap(
                  cur[:from][:content_sim],
                  nxt[:to][:content_sim],
                  overlap_threshold
                ) > 0
              )
                # Subtitles overlap, connected with next
                return true
              else
                # No overlap, terminate capture group
                return false
              end
            elsif :st_added == nxt[:type]
              if(
                # Overlap with next
                StringComputations.overlap(
                  cur[:from][:content_sim],
                  nxt[:to][:content_sim],
                  overlap_threshold
                ) > 0
              )
                return true
              elsif(
                # Overlap with next but one
                nbo &&
                ![:left_aligned, :fully_aligned].include?(nbo[:type]) &&
                if @asp_group_cumulative_content_change > 0
                  # Longer `to`, compare (cur_to + nxt_to) with nbo_from
                  StringComputations.overlap(
                    [cur[:to][:content_sim], nxt[:to][:content_sim]].join(' '),
                    nbo[:from][:content_sim],
                    overlap_threshold
                  )
                else
                  # Longer `from`, compare cur_from with (nxt_to + nbo_to)
                  StringComputations.overlap(
                    cur[:from][:content_sim],
                    [nxt[:to][:content_sim], nbo[:to][:content_sim]].join(' '),
                    overlap_threshold
                  )
                end
              )
                # Subtitles overlap, connected with next but one
                nxt[:linked_to_next] = true
                return true
              else
                # No overlap, terminate capture group
                return false
              end
            elsif :st_removed == nxt[:type]
              if(
                # Overlap with next
                StringComputations.overlap(
                  cur[:to][:content_sim],
                  nxt[:from][:content_sim],
                  overlap_threshold
                ) > 0
              )
                return true
              elsif(
                # Overlap with next but one
                nbo &&
                ![:left_aligned, :fully_aligned].include?(nbo[:type]) &&
                if @asp_group_cumulative_content_change > 0
                  # Longer `to`, compare cur_to with (nxt_from + nbo_from)
                  StringComputations.overlap(
                    cur[:to][:content_sim],
                    [nxt[:from][:content_sim], nbo[:from][:content_sim]].join(' '),
                    overlap_threshold
                  )
                else
                  # Longer `from`, compare (cur_from + nxt_from) with nbo_to
                  StringComputations.overlap(
                    [cur[:from][:content_sim], nxt[:from][:content_sim]].join(' '),
                    nbo[:to][:content_sim],
                    overlap_threshold
                  )
                end
              )
                # Subtitles overlap, connected with next
                nxt[:linked_to_next] = true
                return true
              else
                # No overlap, terminate capture group
                return false
              end
            else
              raise "Should never get here!"
            end
          end

          def capture_op(op_type)
            reported_op_type = op_type
            op = case op_type
            when :content_change
              Subtitle::Operation.new_from_hash(
                affectedStids: [@current_asp[:subtitle_object]],
                operationId: compute_next_operation_id!,
                operationType: :content_change,
              )
            when :delete
              if(prev_op = @ops_in_group.last) && :merge == prev_op.operationType
                # Don't record separate :delete operation, just add @current_asp
                # to affectedStids.
                prev_op.affectedStids << @current_asp[:subtitle_object]
                reported_op_type = :merge_combo
                nil
              else
                Subtitle::Operation.new_from_hash(
                  affectedStids: [@current_asp[:subtitle_object]],
                  operationId: compute_next_operation_id!,
                  operationType: :delete,
                )
              end
            when :insert
              if(prev_op = @ops_in_group.last) && :split == prev_op.operationType
                # Don't record separate :insert operation, just add @current_asp
                # to affectedStids.
                prev_op.affectedStids << @current_asp[:subtitle_object]
                reported_op_type = :split_combo
                nil
              else
                Subtitle::Operation.new_from_hash(
                  affectedStids: [@current_asp[:subtitle_object]],
                  operationId: compute_next_operation_id!,
                  operationType: :insert,
                  afterStid: @prev_stid,
                )
              end
            when :merge
              if(prev_op = @ops_in_group.last) && :merge == prev_op.operationType
                # Don't record separate operation, just add @current_asp to
                # affectedStids
                prev_op.affectedStids << @current_asp[:subtitle_object]
                reported_op_type = :merge_combo
                nil
              else
                # record new operation
                Subtitle::Operation.new_from_hash(
                  affectedStids: [@prev_asp, @current_asp].map { |e| e[:subtitle_object] },
                  operationId: compute_next_operation_id!,
                  operationType: :merge,
                )
              end
            when :move_left
              Subtitle::Operation.new_from_hash(
                affectedStids: [@prev_asp, @current_asp].map { |e| e[:subtitle_object] },
                operationId: compute_next_operation_id!,
                operationType: :move_left,
              )
            when :move_right
              Subtitle::Operation.new_from_hash(
                affectedStids: [@prev_asp, @current_asp].map { |e| e[:subtitle_object] },
                operationId: compute_next_operation_id!,
                operationType: :move_right,
              )
            when :no_op
              # Nothing to do
              nil
            when :split
              if(prev_op = @ops_in_group.last) && :split == prev_op.operationType
                # Don't record separate operation, just add @current_asp to
                # affectedStids
                prev_op.affectedStids << @current_asp[:subtitle_object]
                reported_op_type = :split_combo
                nil
              else
                # record new operation
                Subtitle::Operation.new_from_hash(
                  affectedStids: [@prev_asp, @current_asp].map { |e| e[:subtitle_object] },
                  operationId: compute_next_operation_id!,
                  operationType: :split,
                )
              end
            else
              raise "Handle this: #{ op_type.inspect }"
            end
            if op
              @ops_in_group << op
              @ops_in_file << op
            end
            puts "   OP: #{ reported_op_type }"  if debug
          end

          def compute_move_direction
            case @current_asp[:type]
            when :right_aligned
              # Right edge is aligned, so we can look at length change of current ASP
              if @current_asp[:content_length_change] < 0
                # current asp got shorter, move right
                :move_right
              else
                # current asp got longer, move left
                :move_left
              end
            when :unaligned
              # Right edge is unaligned, we have to look at capture group's length change
              ccc_before_current_asp = @asp_group_cumulative_content_change - @current_asp[:content_length_change]
              if ccc_before_current_asp < 0
                # Capture group has gotten shorter up to @current_asp => move left
                :move_left
              else
                # Capture group has gotten longer up to @current_asp => move right
                :move_right
              end
            else
              raise "Handle this: #{ @current_asp.inspect }"
            end
          end

          # Calling this method increments the @operation_index i_var!
          # @param asp_index [Integer] index of operation in file.
          def compute_next_operation_id!
            [@file_date_code, @file_operation_index += 1].join('_')
          end

          def debug
            true
          end

        end
      end
    end
  end
end
