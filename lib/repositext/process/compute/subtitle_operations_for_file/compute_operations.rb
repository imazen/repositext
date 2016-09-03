class Repositext
  class Process
    class Compute
      class SubtitleOperationsForFile
        module ComputeOperations

          # Takes groups of aligned subtitle pairs and computes their subtitle
          # operations.
          # @param asp_groups [Array<Array<AlignedSubtitlePair>>]
          # @return [Array<Subtitle::Operation>]
          def compute_operations(asp_groups)
            collected_operations = []
            previous_subtitle_object = nil
            asp_groups.each { |asp_group|
              # Get previous stid from previous subtitle object or initial val
              prev_stid = if previous_subtitle_object.nil?
                'new_file'
              else
                previous_subtitle_object.persistent_id
              end

              # Return early if all operations in asp_group are insertions or deletions
              if(ops = detect_pure_insertions_or_deletions(asp_group, prev_stid)).any?
                collected_operations += ops
                previous_subtitle_id = asp_group.last[:subtitle_object]
                next
              elsif(ops = detect_pure_moves(asp_group)).any?
                collected_operations += ops
                previous_subtitle_id = asp_group.last[:subtitle_object]
                next
              end

              case asp_group.length
              when 0
                # No aligned_subtitle_pairs in group. Raise exception!
                raise "handle this!"
              when 1
                collected_operations += compute_operations_for_asp_group_of_1(
                  asp_group,
                  prev_stid
                )
              when 2
                collected_operations += compute_operations_for_asp_group_of_2(
                  asp_group,
                  prev_stid
                )
              when 3
                collected_operations += compute_operations_for_asp_group_of_3(
                  asp_group,
                  prev_stid
                )
              when 4
                collected_operations += compute_operations_for_asp_group_of_4(
                  asp_group,
                  prev_stid
                )
              else
                raise "Handle this: #{ asp_group.inspect }"
              end
              previous_subtitle_object = asp_group.last[:subtitle_object]
            }
            collected_operations
          end

          # Checks if the asp_group contains only insertions or deletions and
          # returns the operations. Otherwise it returns an empty array.
          # @param asp_group [Array<AlignedSubtitlePair>]
          # @param previous_subtitle_id [String, Nil]
          # @return [Array<Subtitle::Operation>]
          def detect_pure_insertions_or_deletions(asp_group, previous_subtitle_id)
            if(
              asp_group.any? { |e| :st_added == e[:type] } &&
              asp_group.all? { |e| [:st_added, :fully_aligned].include?(e[:type]) }
            )
              # TODO: There should be no :fully_aligneds here!
              # Contains at least one :st_added, and maybe some :fully_aligned.
              # This is an insertion.
              after_stid = previous_subtitle_id
              asp_group.map { |e|
                r = nil
                if :st_added == e[:type]
                  r = Subtitle::Operation.new_from_hash(
                    affectedStids: [e[:subtitle_object]],
                    operationId: e[:index],
                    operationType: :insert,
                    afterStid: after_stid,
                  )
                end
                after_stid = e[:subtitle_object].persistent_id
                r
              }.compact
            elsif(
              asp_group.any? { |e| :st_removed == e[:type] } &&
              asp_group.all? { |e| [:st_removed, :fully_aligned].include?(e[:type]) }
            )
              # Contains at least one :st_removed, and maybe some :fully_aligned.
              # This is a deletion.
              after_stid = previous_subtitle_id
              asp_group.map { |e|
                r = nil
                if :st_removed == e[:type]
                  r = Subtitle::Operation.new_from_hash(
                    affectedStids: [e[:subtitle_object]],
                    operationId: e[:index],
                    operationType: :delete,
                  )
                end
                after_stid = e[:subtitle_object].persistent_id
                r
              }.compact
            else
              # Contains other operations, return empty array
              []
            end
          end

          # Checks if the asp_group contains only moves and returns
          # the operations. Otherwise it returns an empty array.
          def detect_pure_moves(asp_group)
            if(
              asp_group.count > 1 &&
              asp_group.all? { |e|
                [:left_aligned, :right_aligned, :unaligned].include?(e[:type])
              }
            )
              # Contains only moves
              collected_operations = []
              asp_group_index = asp_group.first[:index]
              asp_group_subtitle_objects = asp_group.map { |e| e[:subtitle_object] }
              cumulative_length_changes = asp_group.inject([0]) { |m,e|
                m << m.last + e[:content_length_change]
              }[1..-1] # Discard first one, is zero
              moves_count = asp_group.count - 1

              moves_count.times.each { |idx|
                op_type = if cumulative_length_changes[idx] < 0
                  # First pair's content got shorter => move left
                  :moveLeft
                else
                  # First pair's content got longer => move right
                  :moveRight
                end
                collected_operations << Subtitle::Operation.new_from_hash(
                  affectedStids: asp_group_subtitle_objects[idx,2],
                  operationId: asp_group_index + idx,
                  operationType: op_type,
                )
              }

              collected_operations
            else
              # Contains other operations, return empty array
              []
            end
          end

          # Computes subtitle operations for asp_group with one aligned subtitle
          # pair.
          # @param asp_group [Array<AlignedSubtitlePair>]
          # @param previous_subtitle_id [String, Nil]
          # @return [Array<Subtitle::Operation>]
          def compute_operations_for_asp_group_of_1(asp_group, previous_subtitle_id)
            asp_group_signature = asp_group.map { |e| e[:type] }
            asp_group_subtitle_objects = asp_group.map { |e| e[:subtitle_object] }
            asp_group_index = asp_group.first[:index]
            collected_operations = []
            prev_st_id = previous_subtitle_id

            case asp_group_signature
            when [:left_aligned]
              # Content change. We don't track this.
            when [:right_aligned]
              # Content change. We don't track this.
            when [:st_added]
              collected_operations << Subtitle::Operation.new_from_hash(
                affectedStids: asp_group_subtitle_objects,
                operationId: asp_group_index,
                operationType: :insert,
                afterStid: previous_subtitle_id,
              )
            when [:st_removed]
              collected_operations << Subtitle::Operation.new_from_hash(
                affectedStids: asp_group_subtitle_objects,
                operationId: aligned_subtitle_pair[:index],
                operationType: :delete,
                afterStid: previous_subtitle_id,
              )
            when [:unaligned]
              # Content change. We don't track this.
            else
              raise "Handle this: #{ aligned_subtitle_pair.inspect }"
            end

            collected_operations
          end

          # Computes subtitle operations for asp_group with two aligned subtitle
          # pairs.
          # @param asp_group [Array<AlignedSubtitlePair>]
          # @param previous_subtitle_id [String, Nil]
          # @return [Array<Subtitle::Operation>]
          def compute_operations_for_asp_group_of_2(asp_group, previous_subtitle_id)
            asp_group_signature = asp_group.map { |e| e[:type] }
            asp_group_subtitle_objects = asp_group.map { |e| e[:subtitle_object] }
            asp_group_index = asp_group.first[:index]
            collected_operations = []
            prev_st_id = previous_subtitle_id

            case asp_group_signature
            when [:left_aligned, :st_added],
                 [:unaligned, :st_added]
              # A split
              collected_operations << Subtitle::Operation.new_from_hash(
                affectedStids: asp_group_subtitle_objects,
                operationId: asp_group_index,
                operationType: :split,
              )
            when [:st_added, :right_aligned],
                 [:st_added, :unaligned]
              # An insert and a move
              # Handle insert
              collected_operations << Subtitle::Operation.new_from_hash(
                affectedStids: asp_group_subtitle_objects[0,1],
                operationId: asp_group_index,
                operationType: :insert,
                afterStid: previous_subtitle_id,
              )
              # Handle move
              op_type = if asp_group.last[:content_length_change] > 0
                # Last pair's content got longer => move left
                :moveLeft
              else
                # Last pair's content got shorter => move right
                :moveRight
              end
              collected_operations << Subtitle::Operation.new_from_hash(
                affectedStids: asp_group_subtitle_objects[1,2],
                operationId: asp_group_index + 1,
                operationType: op_type,
              )
            when [:left_aligned, :st_removed],
                 [:unaligned, :st_removed]
              # A merge
              collected_operations << Subtitle::Operation.new_from_hash(
                affectedStids: asp_group_subtitle_objects,
                operationId: asp_group_index,
                operationType: :merge,
              )
            when [:st_removed, :right_aligned],
                 [:st_removed, :unaligned]
              # A delete and a move
              # Handle delete
              collected_operations << Subtitle::Operation.new_from_hash(
                affectedStids: asp_group_subtitle_objects[0,1],
                operationId: asp_group_index,
                operationType: :delete,
              )
              # Handle move
              op_type = if asp_group.last[:content_length_change] > 0
                # Last pair's content got longer => move left
                :moveLeft
              else
                # Last pair's content got shorter => move right
                :moveRight
              end
              collected_operations << Subtitle::Operation.new_from_hash(
                affectedStids: asp_group_subtitle_objects[1,2],
                operationId: asp_group_index + 1,
                operationType: op_type,
              )
            else
              raise "Handle this: #{ asp_group.inspect }"
            end

            collected_operations
          end

          # Computes subtitle operations for asp_group with three aligned subtitle
          # pairs.
          # @param asp_group [Array<AlignedSubtitlePair>]
          # @param previous_subtitle_id [String, Nil]
          # @return [Array<Subtitle::Operation>]
          def compute_operations_for_asp_group_of_3(asp_group, previous_subtitle_id)
            asp_group_signature = asp_group.map { |e| e[:type] }
            asp_group_subtitle_objects = asp_group.map { |e| e[:subtitle_object] }
            asp_group_index = asp_group.first[:index]
            collected_operations = []
            prev_st_id = previous_subtitle_id

            case asp_group_signature
            when [:left_aligned, :st_added, :right_aligned],
                 [:left_aligned, :st_added, :unaligned],
                 [:unaligned, :st_added, :right_aligned]
              # A split and a move
              # Process split
              collected_operations << Subtitle::Operation.new_from_hash(
                affectedStids: asp_group_subtitle_objects[0,2],
                operationId: asp_group_index,
                operationType: :split,
              )
              # Process move
              op_type = if asp_group.last[:content_length_change] > 0
                # Last pair's content got longer => move left
                :moveLeft
              else
                # Last pair's content got shorter => move right
                :moveRight
              end
              collected_operations << Subtitle::Operation.new_from_hash(
                affectedStids: asp_group_subtitle_objects[1,2],
                operationId: asp_group_index + 1,
                operationType: op_type,
              )
            when [:left_aligned, :unaligned, :st_added],
                 [:unaligned, :unaligned, :st_added]
              # A move and a split
              # Process move
              op_type = if asp_group.first[:content_length_change] < 0
                # First pair's content got shorter => move left
                :moveLeft
              else
                # First pair's content got longer => move right
                :moveRight
              end
              collected_operations << Subtitle::Operation.new_from_hash(
                affectedStids: asp_group_subtitle_objects[0,2],
                operationId: asp_group_index,
                operationType: op_type,
              )
              # Process split
              collected_operations << Subtitle::Operation.new_from_hash(
                affectedStids: asp_group_subtitle_objects[1,2],
                operationId: asp_group_index + 1,
                operationType: :split,
              )
            when [:left_aligned, :st_removed, :right_aligned],
                 [:unaligned, :st_removed, :right_aligned]
              # A merge and a move
              # Process merge
              collected_operations << Subtitle::Operation.new_from_hash(
                affectedStids: asp_group_subtitle_objects[0,2],
                operationId: asp_group_index,
                operationType: :merge,
              )
              # Process move
              op_type = if asp_group.last[:content_length_change] > 0
                # Last pair's content got longer => move left
                :moveLeft
              else
                # Last pair's content got shorter => move right
                :moveRight
              end
              collected_operations << Subtitle::Operation.new_from_hash(
                affectedStids: asp_group_subtitle_objects[1,2],
                operationId: asp_group_index + 1,
                operationType: op_type,
              )
            when [:left_aligned, :unaligned, :st_removed]
              # A move and a merge
              # Process move
              op_type = if asp_group.first[:content_length_change] < 0
                # First pair's content got shorter => move left
                :moveLeft
              else
                # First pair's content got longer => move right
                :moveRight
              end
              collected_operations << Subtitle::Operation.new_from_hash(
                affectedStids: asp_group_subtitle_objects[0,2],
                operationId: asp_group_index,
                operationType: op_type,
              )
              # Process merge
              collected_operations << Subtitle::Operation.new_from_hash(
                affectedStids: asp_group_subtitle_objects[1,2],
                operationId: asp_group_index + 1,
                operationType: :merge,
              )
            else
              raise "Handle this: #{ asp_group.inspect }"
            end

            collected_operations
          end

          # Computes subtitle operations for asp_group with four aligned subtitle
          # pairs.
          # @param asp_group [Array<AlignedSubtitlePair>]
          # @param previous_subtitle_id [String, Nil]
          # @return [Array<Subtitle::Operation>]
          def compute_operations_for_asp_group_of_4(asp_group, previous_subtitle_id)
            asp_group_signature = asp_group.map { |e| e[:type] }
            asp_group_subtitle_objects = asp_group.map { |e| e[:subtitle_object] }
            asp_group_index = asp_group.first[:index]
            collected_operations = []
            prev_st_id = previous_subtitle_id
            cumulative_length_changes = asp_group.inject([0]) { |m,e|
              m << m.last + e[:content_length_change]
            }[1..-1] # Discard first one, is zero

            case asp_group_signature
            when [:left_aligned, :st_added, :unaligned, :right_aligned],
                 [:left_aligned, :st_added, :unaligned, :unaligned]
              # A split and two moves
              # Process split
              collected_operations << Subtitle::Operation.new_from_hash(
                affectedStids: asp_group_subtitle_objects[0,2],
                operationId: asp_group_index,
                operationType: :split,
              )
              2.times.each { |idx|
                op_type = if cumulative_length_changes[idx+1] < 0
                  # First pair's content got shorter => move left
                  :moveLeft
                else
                  # First pair's content got longer => move right
                  :moveRight
                end
                collected_operations << Subtitle::Operation.new_from_hash(
                  affectedStids: asp_group_subtitle_objects[idx+1,2],
                  operationId: asp_group_index + idx + 1,
                  operationType: op_type,
                )
              }
            when [:left_aligned, :unaligned, :st_added, :right_aligned],
                 [:left_aligned, :unaligned, :st_added, :unaligned]
              # A move, a split, and a move
              # Process first move
              op_type = if cumulative_length_changes[0] < 0
                # First pair's content got shorter => move left
                :moveLeft
              else
                # First pair's content got longer => move right
                :moveRight
              end
              collected_operations << Subtitle::Operation.new_from_hash(
                affectedStids: asp_group_subtitle_objects[0,2],
                operationId: asp_group_index,
                operationType: op_type,
              )
              # Process split
              collected_operations << Subtitle::Operation.new_from_hash(
                affectedStids: asp_group_subtitle_objects[1,2],
                operationId: asp_group_index + 1,
                operationType: :split,
              )
              # Process second move
              op_type = if cumulative_length_changes[2] < 0
                # First pair's content got shorter => move left
                :moveLeft
              else
                # First pair's content got longer => move right
                :moveRight
              end
              collected_operations << Subtitle::Operation.new_from_hash(
                affectedStids: asp_group_subtitle_objects[2,2],
                operationId: asp_group_index + 2,
                operationType: op_type,
              )
            else
              raise "Handle this: #{ asp_group.inspect }"
            end

            collected_operations
          end
        end
      end
    end
  end
end
