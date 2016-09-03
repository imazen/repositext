class Repositext
  class Process
    class Compute
      class SubtitleOperationsForFile
        class OperationExtractor

          def initialize(aligned_subtitle_pairs)
            @aligned_subtitle_pairs = aligned_subtitle_pairs
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
            @current_asp = @aligned_subtitle_pairs[0]
            @next_asp = @aligned_subtitle_pairs[1]
            @ops_in_file = []
            @prev_stid = 'new_file'
            reset_current_capture_group
          end

          def process_current_asp

            @asp_group_cumulative_content_change += @current_asp[:content_length_change]
            @asp_group_cumulative_content_length_to += @current_asp[:to][:content].length

            if debug
              puts "P"  if @current_asp[:first_in_para]
              puts " - #{ @current_asp[:type] }"
              just_method = case @current_asp[:type]
              when :right_aligned
                :rjust
              when :left_aligned, :fully_aligned
                :ljust
              when :unaligned, :st_added, :st_removed
                :center
              else
                raise "Handle this: #{ @current_asp[:type] }"
              end
              para_boundaries_reporter = ->(st_attrs) {
                [
                  (st_attrs[:first_in_para] ? 'first_ip' : nil),
                  (st_attrs[:last_in_para] ? 'last_ip' : nil)
                ].compact.join(', ')
              }
              puts "   From: #{ @current_asp[:from][:content].strip.send(just_method, 130) }   #{ para_boundaries_reporter.call(@current_asp[:from]) }"
              puts "   To:   #{ @current_asp[:to][:content].strip.send(just_method, 130) }   #{ para_boundaries_reporter.call(@current_asp[:to]) }"
              puts([
                "   ",
                "clc:#{ @current_asp[:content_length_change] } ",
                "ccc:#{ @asp_group_cumulative_content_change } ",
                "sl:#{ @current_asp[:sim_left] } ",
                "sa:#{ @current_asp[:sim_abs] } ",
                "sr:#{ @current_asp[:sim_right] } ",
              ].join)
            end

            case @prev_right_edge

            when :aligned
              case @current_asp[:type]
              when :fully_aligned
                if @current_asp[:from][:content] == @current_asp[:to][:content]
                  capture_op(:no_op)
                else
                  capture_op(:content_change)
                end
                reset_current_capture_group
              when :left_aligned, :unaligned
                if current_right_edge_aligned?
                  capture_op(:content_change)
                  reset_current_capture_group
                else
                  @prev_right_edge = :unaligned
                end
              when :right_aligned
                capture_op(:content_change)
                reset_current_capture_group
              when :st_added
                capture_op(:insert)
                if current_right_edge_aligned?
                  reset_current_capture_group
                else
                  @prev_right_edge = :unaligned
                end
              when :st_removed
                capture_op(:delete)
                if current_right_edge_aligned?
                  reset_current_capture_group
                else
                  @prev_right_edge = :unaligned
                end
              else
                raise "Handle this! #{ @current_asp.inspect }"
              end

            when :unaligned
              case @current_asp[:type]
              when :fully_aligned, :left_aligned
                raise "Handle this! #{ @current_asp.inspect }"
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
                if current_right_edge_aligned?
                  reset_current_capture_group
                else
                  @prev_right_edge = :unaligned
                end
              when :st_removed
                if :st_removed == @prev_asp[:type] && :delete == @ops_in_group.last.operationType
                  # This is a subsequent :delete
                  capture_op(:delete)
                else
                  # It's a merge
                  capture_op(:merge)
                end
                if current_right_edge_aligned?
                  reset_current_capture_group
                else
                  @prev_right_edge = :unaligned
                end
              when :unaligned
                capture_op(compute_move_direction)
                if current_right_edge_aligned?
                  reset_current_capture_group
                else
                  @prev_right_edge = :unaligned
                end
              else
                raise "Handle this! #{ @current_asp.inspect }"
              end
            else
              raise "Handle this! #{ @prev_right_edge }"
            end

            puts "P"  if debug && @current_asp[:last_in_para]
          end

          def advance_to_next_asp
            @prev_asp = @current_asp
            @current_asp = @aligned_subtitle_pairs[@current_asp_index += 1]
            @next_asp = @aligned_subtitle_pairs[@current_asp_index + 1]
            @prev_stid = if @prev_asp[:subtitle_object].nil?
              'new_file'
            else
              @prev_asp[:subtitle_object].persistent_id
            end
          end

          def reset_current_capture_group
            @prev_right_edge = :aligned
            @asp_group_cumulative_content_change = 0
            @asp_group_cumulative_content_length_to = 0
            @ops_in_group = []
          end

          def current_right_edge_aligned?
            cur = @current_asp
            nxt = @next_asp
            if nxt.nil?
              # current_asp is the last in file
              return true
            elsif [:fully_aligned, :left_aligned].include?(nxt[:type])
              # next_asp has clear left boundary
              return true
            elsif [:right_aligned, :unaligned].include?(nxt[:type])
              # next_asp has no left boundary
              return false
            elsif [:st_added, :st_removed].include?(nxt[:type])
              # next_asp may be connected to current_asp
              return false
            else
              raise "Should never get here!"
            end
          end

          def capture_op(op_type)
            op = case op_type
            when :content_change
              # Nothing to do
              nil
            when :delete
              if(prev_op = @ops_in_group.last) && :delete == prev_op.operationType
                # Don't record separate operation, just add @current_asp to
                # affectedStids
                prev_op.affectedStids << @current_asp[:subtitle_object]
                nil
              else
                # record new operation
                Subtitle::Operation.new_from_hash(
                  affectedStids: [@current_asp[:subtitle_object]],
                  operationId: @current_asp[:index],
                  operationType: :delete,
                )
              end
            when :insert
              if(prev_op = @ops_in_group.last) && :insert == prev_op.operationType
                # Don't record separate operation, just add @current_asp to
                # affectedStids
                prev_op.affectedStids << @current_asp[:subtitle_object]
                nil
              else
                # record new operation
                Subtitle::Operation.new_from_hash(
                  affectedStids: [@current_asp[:subtitle_object]],
                  operationId: @current_asp[:index],
                  operationType: :insert,
                  afterStid: @prev_stid,
                )
              end
            when :merge
              if(prev_op = @ops_in_group.last) && :merge == prev_op.operationType
                # Don't record separate operation, just add @current_asp to
                # affectedStids
                prev_op.affectedStids << @current_asp[:subtitle_object]
                nil
              else
                # record new operation
                Subtitle::Operation.new_from_hash(
                  affectedStids: [@prev_asp, @current_asp].map { |e| e[:subtitle_object] },
                  operationId: @prev_asp[:index],
                  operationType: :merge,
                )
              end
            when :move_left
              Subtitle::Operation.new_from_hash(
                affectedStids: [@prev_asp, @current_asp].map { |e| e[:subtitle_object] },
                operationId: @prev_asp[:index],
                operationType: :move_left,
              )
            when :move_right
              Subtitle::Operation.new_from_hash(
                affectedStids: [@prev_asp, @current_asp].map { |e| e[:subtitle_object] },
                operationId: @prev_asp[:index],
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
                nil
              else
                # record new operation
                Subtitle::Operation.new_from_hash(
                  affectedStids: [@prev_asp, @current_asp].map { |e| e[:subtitle_object] },
                  operationId: @prev_asp[:index],
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
            puts "   OP: #{ op_type }".color(:blue)  if debug
          end

          def compute_move_direction
            ccc_before_current_asp = @asp_group_cumulative_content_change - @current_asp[:content_length_change]
            if ccc_before_current_asp < 0
              # Capture group has gotten shorter up to @current_asp => move left
              :move_left
            else
              # Capture group has gotten longer up to @current_asp => move right
              :move_right
            end
          end

          def debug
            true
          end
        end
      end
    end
  end
end
