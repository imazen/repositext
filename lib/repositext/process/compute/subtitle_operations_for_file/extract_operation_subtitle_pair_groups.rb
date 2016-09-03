class Repositext
  class Process
    class Compute
      class SubtitleOperationsForFile
        module ExtractOperationSubtitlePairGroups

          # Takes all the file's aligned_subtitle_pairs, extracts the ones that
          # contain subtitle operations and groups them according to various
          # boundaries. Uses a state_machine to do so.
          # Returns an Array of Arrays of AlignedSubtitlePair items.
          # @param aligned_subtitle_pairs [Array<AlignedSubtitlePair>]
          # @return [Array<Array<AlignedSubtitlePair>>]
          def extract_operation_subtitle_pair_groups(aligned_subtitle_pairs)
            @fsm = init_fsm
            @fsm_trigger_auto_event = nil
            reset_operations_group!
            collected_asp_groups = []

            # Iterate over all aligned subtitle pairs and compute operations_groups
            aligned_subtitle_pairs.each_with_index { |al_st_pair, idx|
              @operations_group_subtitle_pair_types << al_st_pair[:type]
              @operations_group_aligned_subtitle_pairs << al_st_pair

              @fsm.trigger!(al_st_pair[:type])

              # Finalize operations_group based on lookahead to next subtitle pair
              next_al_st_pair = aligned_subtitle_pairs[idx+1]
              if(
                al_st_pair[:last_in_para] ||
                next_al_st_pair.nil? ||
                [:left_aligned, :fully_aligned].include?(next_al_st_pair[:type])
              ) && :operations_group_active == @fsm.state
                @fsm.trigger!(:end_operations_group)
              end

              # Check if an operations_group has been completed
              case @operations_group_type
              when :no_operation
                # No operations to record, reset group
                reset_operations_group!
              when :operations_group_found
                # Collect operations_group and reset
                collected_asp_groups << @operations_group_aligned_subtitle_pairs
                reset_operations_group!
              when nil
                # No operations to record
              else
                puts "Handle this! #{ @operations_group_type.inspect }"
              end

              # Check if we need to trigger an auto event
              if(tae = @fsm_trigger_auto_event)
                @fsm.trigger!(tae)
                @fsm_trigger_auto_event = nil
              end
            }

            if :idle != @fsm.state
              raise "Uncompleted operation analysis for file!"
            end
            collected_asp_groups
          end

          # An FSM to track operations state when iterating over aligned subtitle
          # pairs. Detects operations group boundaries and triggers actions as
          # required.
          # @return [Micromachine]
          def init_fsm
            fsm = MicroMachine.new(:idle)

            # Define state transitions

            # Explicit transitions
            fsm.when(
              :end_operations_group,
              operations_group_active: :operations_group_found,
            )
            # Identical pair
            fsm.when(
              :fully_aligned,
              idle: :no_operation,
            )
            # Left aligned pair
            fsm.when(
              :left_aligned,
              idle: :operations_group_active,
            )
            # Right aligned pair
            fsm.when(
              :right_aligned,
              idle: :operations_group_found,
              operations_group_active: :operations_group_found,
            )
            # A subtitle was added
            fsm.when(
              :st_added,
              idle: :operations_group_active,
              operations_group_active: :operations_group_active,
            )
            # A subtitle was removed
            fsm.when(
              :st_removed,
              idle: :operations_group_active,
              operations_group_active: :operations_group_active,
            )
            # Not aligned
            fsm.when(
              :unaligned,
              idle: :operations_group_active,
              operations_group_active: :operations_group_active,
            )
            # Back to idle
            fsm.when(
              :reset,
              no_operation: :idle,
              operations_group_found: :idle,
            )

            # Define callbacks at state entry
            fsm.on(:no_operation) do
              @operations_group_type = :no_operation
              @fsm_trigger_auto_event = :reset
            end

            fsm.on(:operations_group_found) do
              @operations_group_type = :operations_group_found
              @fsm_trigger_auto_event = :reset
            end

            fsm.on(:reset) do
              reset_operations_group!
            end

            fsm
          end

          # Resets state when starting with a new operations_group.
          def reset_operations_group!
            @operations_group_type = nil
            @operations_group_subtitle_pair_types = []
            @operations_group_aligned_subtitle_pairs = []
          end

          def collect_signature_data(op_asp_groups)
            signatures = Hash.new(0)
            # total_asps_count = aligned_subtitle_pairs.count
            # aligned_subtitle_pairs.each_with_index { |asp, idx|
            #   6.times.each do |length|
            #     # Special treatment at the end
            #     next  if idx + length > total_asps_count

            #     key = aligned_subtitle_pairs[idx,length+1].map { |e| e[:type] }
            #     signatures[key] += 1
            #   end
            # }

            op_asp_groups.each { |asp_group|
              key = asp_group.map { |e| e[:type] }
              signatures[key] += 1
            }
            pp signatures
          end
        end
      end
    end
  end
end
