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
            @current_asp = @aligned_subtitle_pairs[0]
            @file_operation_index = 0
            @next_asp = @aligned_subtitle_pairs[1]
            @ops_in_file = []
            @prev_stid = 'new_file'
            reset_current_capture_group
          end

          def process_current_asp

            curr = @current_asp

            @asp_group_cumulative_content_change += curr[:content_length_change]
            @asp_group_cumulative_content_length_to += curr[:to][:content].length

            if debug
              puts "P"  if curr[:first_in_para]
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
              puts "   From: #{ curr[:from][:content].strip.send(just_method, 130) }   #{ para_boundaries_reporter.call(curr[:from]) }"
              puts "   To:   #{ curr[:to][:content].strip.send(just_method, 130) }   #{ para_boundaries_reporter.call(curr[:to]) }"
              puts([
                "   ",
                "clc:#{ curr[:content_length_change] } ",
                "ccc:#{ @asp_group_cumulative_content_change } ",
                "sl:#{ curr[:sim_left] } ",
                "sa:#{ curr[:sim_abs] } ",
                "sr:#{ curr[:sim_right] } ",
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
                if strong_linkage_with_next_asp?
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
                if strong_linkage_with_next_asp?
                  @prev_right_edge = :unaligned
                else
                  reset_current_capture_group
                end
              when :st_removed
                # Removed subtitle, not connected to previous: delete.
                capture_op(:delete)
                if strong_linkage_with_next_asp?
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
                if strong_linkage_with_next_asp?
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
                if strong_linkage_with_next_asp?
                  @prev_right_edge = :unaligned
                else
                  reset_current_capture_group
                end
              when :unaligned
                capture_op(compute_move_direction)
                if strong_linkage_with_next_asp?
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

          # Computes strength of linkage between @current_asp and @next_asp
          # @return [Boolean]
          def strong_linkage_with_next_asp?
            cur = @current_asp
            nxt = @next_asp
            if nxt.nil?
              # current_asp is the last in file
              return false
            elsif [:fully_aligned, :left_aligned].include?(nxt[:type])
              # next_asp has clear left boundary
              return false
            elsif [:right_aligned, :unaligned].include?(nxt[:type])
              if(
                @asp_group_cumulative_content_change > 10 &&
                (
                  @asp_group_cumulative_content_change + nxt[:content_length_change]
                ) < 3
              ) || (
                compute_string_overlap(cur[:to][:content_sim], nxt[:from][:content_sim]) > 0 ||
                compute_string_overlap(cur[:from][:content_sim], nxt[:to][:content_sim]) > 0
              )
                # Subtitles overlap, connected with next
                return true
              else
                # No overlap, terminate capture group
                return false
              end
            elsif [:st_added, :st_removed].include?(nxt[:type])
              if(
                compute_string_overlap(cur[:to][:content_sim], nxt[:from][:content_sim]) > 0 ||
                compute_string_overlap(cur[:from][:content_sim], nxt[:to][:content_sim]) > 0
              )
                # Subtitles overlap, connected with next
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
                  operationId: compute_operation_id,
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
                  operationId: compute_operation_id,
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
                  operationId: compute_operation_id,
                  operationType: :merge,
                )
              end
            when :move_left
              Subtitle::Operation.new_from_hash(
                affectedStids: [@prev_asp, @current_asp].map { |e| e[:subtitle_object] },
                operationId: compute_operation_id,
                operationType: :move_left,
              )
            when :move_right
              Subtitle::Operation.new_from_hash(
                affectedStids: [@prev_asp, @current_asp].map { |e| e[:subtitle_object] },
                operationId: compute_operation_id,
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
                  operationId: compute_operation_id,
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

          # @param asp_index [Integer] index of ASP in file
          def compute_operation_id
            [@file_date_code, @file_operation_index += 1].join('_')
          end

          # This method measures by how many characters the end of string_a
          # overlaps the beginning of string_b.
          # It determines the overlap in characters at which the similarity
          # surpasses a similarity threshold.
          # NOTE: This method assumes that string_a and string_b are not very
          # similar. This method should only get called for dissimilar strings.
          # If we find we call this for similar strings, then we could further
          # optimize it, e.g., by computing the overall string similarity and
          # returning that if it is high enough.
          # @param string_a [String]
          # @param string_b [String]
          # @min_overlap [Integer, optional]
          # @return [Integer] Number of overlapping characters
          def compute_string_overlap(string_a, string_b, min_overlap=3, debug=false)
            min_string_length = [string_a, string_b].map(&:length).min
            return 0  if 0 == min_string_length

            max_sim = 0
            prev_sim = 0
            overlap = 1 # We start with 2 char overlap
            until(
              (overlap > min_overlap) &&
              (
                (sufficient_overlap_similarity?(max_sim, overlap)) ||
                (overlap >= min_string_length)
              )
            ) do
              overlap += 1
              string_a_end = string_a[-overlap..-1]
              string_b_start = string_b[0..(overlap-1)]
              sim = string_a_end.longest_subsequence_similar(string_b_start)

              if debug
                puts ''
                puts [
                  ('█' * (sim * 10).round).rjust(10),
                  ' ',
                  string_a_end.inspect
                ].join
                puts [
                  sim.round(3).to_s.rjust(10).color(prev_sim <= sim ? :green : :red),
                  ' ',
                  string_b_start.inspect
                ].join
              end

              if sim > max_sim
                optimal_overlap = overlap
              end
              max_sim = [max_sim, sim].max  if overlap >= min_overlap
              prev_sim = sim

            end
            r = if sufficient_overlap_similarity?(max_sim, overlap)
              optimal_overlap
            else
              0
            end
            puts "Returned overlap chars: #{ r }"  if debug
            r
          end

          # Returns true if sim is sufficient for the given overlap.
          # @param sim [Float]
          # @param overlap [Integer]
          # @return [Boolean]
          def sufficient_overlap_similarity?(sim, overlap)
            case overlap
            when 0..2
              false
            when 3..4
              1.0 == sim # 3 of 3, 4 of 4
            when 5..8
              # 4 of 5, 5 of 6, 6 of 7, 7 of 8,
              sim >= 0.8
            when 9..10
              # 7 of 9, 8 of 10
              sim >= 0.75
            when 11..20
              sim > 0.7
            else
              # 90% similarity
              sim > 0.65
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
