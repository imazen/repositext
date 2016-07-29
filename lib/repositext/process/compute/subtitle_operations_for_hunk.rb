class Repositext
  class Process
    class Compute

      # Computes subtitle operations for a hunk
      class SubtitleOperationsForHunk

        # Data types:

        # Hunk
        # Object #line
        #   Renders HunkLine objects: #line_origin, #content, #old_linenos

        # # per_origin_line_group
        # {
        #   line_origin: :addition,
        #   content: '',
        #   old_linenos: []
        # }


        # aligned_subtitle_pair
        # {
        #   type: :gap, # :left_aligned|:right_aligned
        #   subtitle_object: [Repositext::Subtitle, nil],
        #   sim_left: [sim<Float>, conf<Float>],
        #   sim_right: [sim<Float>, conf<Float>],
        #   sim_abs: [sim<Float>, conf<Float>],
        #   content_length_change: [Integer], # from del to add
        #   del: {
        #     content: "word word word",
        #     old_linenos: [3,4,5],
        #   }, # Hunk's deleted line
        #   add: {
        #     content: "word word word",
        #     old_linenos: [3,4,5],
        #   } # Hunk's added line
        #   index: [Integer]
        # }

        # @param content_at_lines_with_subtitles [Array<Hash>]
        #   {
        #     content: "the content",
        #     line_no: 42,
        #     subtitles: [<Subtitle>, ...],
        #   }
        # @param hunk [SubtitleOperationsForFile::Hunk]
        # @param previous_hunk_last_stid [String] the last stid of the previous hunk
        # @param hunk_index [Integer] index of hunk in file
        def initialize(
          content_at_lines_with_subtitles,
          hunk,
          previous_hunk_last_stid,
          hunk_index
        )
          @content_at_lines_with_subtitles = content_at_lines_with_subtitles
          @hunk = hunk
          @previous_stid = previous_hunk_last_stid
          @hunk_index = hunk_index
          @fsm = init_fsm
          @fsm_trigger_auto_event = nil
          reset_operations_group!
        end

        # @return [Hash]
        # { last_stid: String, subtitle_operations: [Array<Subtitle::Operation>] }
        def compute
          # TODO: We may want to sort :addition and :deletion for consistency
          per_origin_line_groups = compute_per_origin_line_groups(@hunk)
          hunk_line_origin_signature = per_origin_line_groups.map { |e|
            e[:line_origin]
          }
          case hunk_line_origin_signature
          when [:addition]
            # Just addition. We create an empty :deletion
            # We set :content to "\n" so that it matches the consistency
            # check in #compute_hunk_operations_for_deletion_addition
            polgs = [
              { line_origin: :deletion, content: "\n", old_linenos: [] },
              per_origin_line_groups[0],
            ]
            compute_hunk_operations_for_deletion_addition(
              @content_at_lines_with_subtitles,
              polgs
            )
          when [:deletion]
            # Just deletion. We create an empty :addition
            # We set :content to "\n" so that it matches the consistency
            # check in #compute_hunk_operations_for_deletion_addition
            polgs = [
              per_origin_line_groups[0],
              { line_origin: :addition, content: "\n", old_linenos: [] },
            ]
            compute_hunk_operations_for_deletion_addition(
              @content_at_lines_with_subtitles,
              polgs
            )
          when [:deletion, :addition]
            compute_hunk_operations_for_deletion_addition(
              @content_at_lines_with_subtitles,
              per_origin_line_groups
            )
          when [:deletion, :addition, :eof_newline_removed]
            # We resolve the eof_newline_removed by adding a newline to :addition's content
            polgs = [
              per_origin_line_groups[0],
              per_origin_line_groups[1].tap { |e| e[:content] << "\n" },
            ]
            compute_hunk_operations_for_deletion_addition(
              @content_at_lines_with_subtitles,
              polgs
            )
          when [:deletion, :eof_newline_added, :addition]
            # We resolve the eof_newline_added by adding a newline to :deletion's content
            polgs = [
              per_origin_line_groups[0].tap { |e| e[:content] << "\n" },
              per_origin_line_groups[1],
            ]
            compute_hunk_operations_for_deletion_addition(
              @content_at_lines_with_subtitles,
              polgs
            )
          else
            puts "per_origin_line_groups:"
            p per_origin_line_groups
            puts "hunk:"
            p @hunk
            raise "Handle this"
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
        #   {
        #     content: "the content",
        #     line_no: 42,
        #     subtitles: [<Subtitle>, ...],
        #   }
        # @param per_origin_line_groups [Array<Hash>]
        #   [
        #     {
        #       line_origin: :addition,
        #       content: "word word word\n",
        #       old_linenos: [3,4,5],
        #     },
        #     ...
        #   ]
        # @return [Hash]
        # { last_stid: String, subtitle_operations: [Array<Subtitle::Operation>] }
        def compute_hunk_operations_for_deletion_addition(
          content_at_lines_with_subtitles,
          per_origin_line_groups
        )
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
          aligner = SubtitleAligner.new(deleted_subtitles, added_subtitles)
          deleted_aligned_subtitles, added_aligned_subtitles = aligner.get_optimal_alignment
          aligned_subtitle_pairs = compute_aligned_subtitle_pairs(
            deleted_aligned_subtitles,
            added_aligned_subtitles,
            hunk_subtitles
          )
          # Use hunk's last stid or previous hunk's last stid
          last_stid = ((ls = hunk_subtitles.last) and ls.persistent_id) || @previous_stid

          # Return early if all operations are insertions or deletions
          if(ops = detect_pure_insertions_or_deletions(aligned_subtitle_pairs)).any?
            return { subtitle_operations: ops, last_stid: last_stid }
          end

          # Otherwise do the more involved operations analysis
          collected_operations_groups = compute_operations_groups(aligned_subtitle_pairs)
          collected_operations = compute_operations(collected_operations_groups)

          {
            subtitle_operations: collected_operations,
            last_stid: last_stid,
          }
        end

        # Checks if the hunk contains only insertions or deletions and returns
        # them here. Otherwise it returns an empty array.
        # @param aligned_subtitle_pairs [Array<Hash>]
        #   {
        #     type: nil, # :left_aligned|:right_aligned|...
        #     subtitle_object: nil, # Repositext::Subtitle, nil
        #     sim_left: [], # [sim<Float>, conf<Float>]
        #     sim_right: [], # [sim<Float>, conf<Float>]
        #     sim_abs: [], # [sim<Float>, conf<Float>]
        #     content_length_change: nil, # Integer from del to add
        #     subtitle_count_change: nil, # Integer from del to add
        #     del: deleted_st, # { content: "word word word", old_linenos: [3,4,5], subtitle_count: 0 } # Hunk's deleted line
        #     add: added_st, # { content: "word word word", old_linenos: [3,4,5]. subtitle_count: 1 } # Hunk's added line
        #     index: [Integer]
        #   }
        # @return [Array<Subtitle::Operation>]
        def detect_pure_insertions_or_deletions(aligned_subtitle_pairs)
          if aligned_subtitle_pairs.all? { |e| [:st_added, :identical].include?(e[:type]) }
            # All insertions
            after_stid = @previous_stid
            aligned_subtitle_pairs.map { |e|
              r = nil
              if :st_added == e[:type]
                r = Subtitle::Operation.new_from_hash(
                  affectedStids: [e[:subtitle_object]],
                  operationId: [@hunk_index, e[:index]].join('-'),
                  operationType: :insert,
                  afterStid: after_stid,
                )
              end
              after_stid = e[:subtitle_object].persistent_id
              r
            }.compact
          elsif aligned_subtitle_pairs.all? { |e| [:st_removed, :identical].include?(e[:type]) }
            # All deletions
            after_stid = @previous_stid
            aligned_subtitle_pairs.map { |e|
              r = nil
              if :st_removed == e[:type]
                r = Subtitle::Operation.new_from_hash(
                  affectedStids: [e[:subtitle_object]],
                  operationId: [@hunk_index, e[:index]].join('-'),
                  operationType: :delete,
                )
              end
              after_stid = e[:subtitle_object].persistent_id
              r
            }.compact
          else
            # Other operations, return empty array
            []
          end
        end

        # @param collected_operations_groups [Array<Hash>]
        #   {
        #     type: nil, # :left_aligned|:right_aligned|...
        #     subtitle_object: nil, # Repositext::Subtitle, nil
        #     sim_left: [], # [sim<Float>, conf<Float>]
        #     sim_right: [], # [sim<Float>, conf<Float>]
        #     sim_abs: [], # [sim<Float>, conf<Float>]
        #     content_length_change: nil, # Integer from del to add
        #     subtitle_count_change: nil, # Integer from del to add
        #     del: deleted_st, # { content: "word word word", old_linenos: [3,4,5], subtitle_count: 0 } # Hunk's deleted line
        #     add: added_st, # { content: "word word word", old_linenos: [3,4,5]. subtitle_count: 1 } # Hunk's added line
        #     index: [Integer]
        #   }
        # @return [Array<Subtitle::Operation>]
        def compute_operations(collected_operations_groups)
          collected_operations = []
          previous_subtitle_object = nil
          collected_operations_groups.each { |operations_group|

            # Get previous stid from previous hunk or previous subtitle object
            after_stid = if previous_subtitle_object.nil?
              @previous_stid
            else
              previous_subtitle_object.persistent_id
            end

            # operations_group is an array of aligned_subtitle_pairs
            og_subtitle_objects = operations_group.map { |e| e[:subtitle_object] }

            case operations_group.length
            when 0
              # No aligned_subtitle_pairs in group. Raise exception!
              raise "handle this!"
            when 1
              # One aligned_subtitle_pair in group, easy to handle.
              aligned_subtitle_pair = operations_group.first
              case aligned_subtitle_pair[:type]
              when :left_aligned
                # Content change. We don't track this.
              when :right_aligned
                # Content change. We don't track this.
              when :st_added
                collected_operations << Subtitle::Operation.new_from_hash(
                  affectedStids: og_subtitle_objects,
                  operationId: [@hunk_index, aligned_subtitle_pair[:index]].join('-'),
                  operationType: :insert,
                  afterStid: after_stid,
                )
              when :st_removed
                collected_operations << Subtitle::Operation.new_from_hash(
                  affectedStids: og_subtitle_objects,
                  operationId: [@hunk_index, aligned_subtitle_pair[:index]].join('-'),
                  operationType: :delete,
                  afterStid: after_stid,
                )
              when :unaligned
                # Content change. We don't track this.
              else
                raise "Handle this: #{ aligned_subtitle_pair.inspect }"
              end
            when 2
              # Two aligned_subtitle_pairs in group, easy to handle
              st_added_count = operations_group.count { |e| :st_added == e[:type] }
              st_removed_count = operations_group.count { |e| :st_removed == e[:type] }
              gap_count = st_added_count + st_removed_count
              case gap_count
              when 0
                # No gaps, it's a move. Let's find out which direction
                op_type = if operations_group[0][:content_length_change] < 0
                  # First pair's content got shorter => move left
                  :moveLeft
                else
                  # First pair's content got longer => move right
                  :moveRight
                end
                collected_operations << Subtitle::Operation.new_from_hash(
                  affectedStids: og_subtitle_objects,
                  operationId: [@hunk_index, operations_group[0][:index]].join('-'),
                  operationType: op_type,
                )
              when 1
                # One gap, it's a merge/split. Let's find out which.
                pair_with_gap = operations_group.detect { |e| 0 != e[:subtitle_count_change] }
                if 1 == st_added_count
                  # a subtitle was added => split
                  collected_operations << Subtitle::Operation.new_from_hash(
                    affectedStids: og_subtitle_objects,
                    operationId: [@hunk_index, pair_with_gap[:index]].join('-'),
                    operationType: :split,
                  )
                elsif 1 == st_removed_count
                  # a subtitle was removed => merge
                  collected_operations << Subtitle::Operation.new_from_hash(
                    affectedStids: og_subtitle_objects,
                    operationId: [@hunk_index, pair_with_gap[:index]].join('-'),
                    operationType: :merge,
                  )
                else
                  raise "Handle this: #{ operations_group.inspect }"
                end
              when 2
                # Two gaps, it's an insertion or deletion, this should have been
                # detected higher up.
                raise "This should have been handled when detecting pure insertions or deletions"
              else
                raise "Handle this: #{ operations_group.inspect }"
              end
            else
              collected_operations += compute_operations_for_group(
                operations_group,
                previous_subtitle_object ? previous_subtitle_object.persistent_id : nil
              )
            end
            #
            previous_subtitle_object = og_subtitle_objects.last
          }
          collected_operations
        end

        # @param aligned_subtitle_pairs [Array<Hash>]
        #   {
        #     type: nil, # :left_aligned|:right_aligned|...
        #     subtitle_object: nil, # Repositext::Subtitle, nil
        #     sim_left: [], # [sim<Float>, conf<Float>]
        #     sim_right: [], # [sim<Float>, conf<Float>]
        #     sim_abs: [], # [sim<Float>, conf<Float>]
        #     content_length_change: nil, # Integer from del to add
        #     subtitle_count_change: nil, # Integer from del to add
        #     del: deleted_st, # { content: "word word word", old_linenos: [3,4,5], subtitle_count: 0 } # Hunk's deleted line
        #     add: added_st, # { content: "word word word", old_linenos: [3,4,5]. subtitle_count: 1 } # Hunk's added line
        #     index: [Integer]
        #   }
        # @return [Array<Hash>] same format as aligned_subtitle_pairs
        def compute_operations_groups(aligned_subtitle_pairs)
          reset_operations_group!
          collected_operations_groups = []

          # Iterate over all aligned subtitle pairs and compute operations_groups
          aligned_subtitle_pairs.each_with_index { |al_st_pair, idx|
            @operations_group_subtitle_pair_types << al_st_pair[:type]
            @operations_group_aligned_subtitle_pairs << al_st_pair

            @fsm.trigger!(al_st_pair[:type])

            # Finalize operations_group based on lookahead to next subtitle pair
            if(
              (next_al_st_pair = aligned_subtitle_pairs[idx+1]).nil? ||
              [:left_aligned, :identical].include?(next_al_st_pair[:type])
            ) && :operations_group_active == @fsm.state
              @fsm.trigger!(:end_operations_group)
            end

            # Check if an operations_group has been completed
            case @operations_group_type
            when :no_operation
              # No operations to record
            when :operations_group_found
              # Collect operations_group
              collected_operations_groups << @operations_group_aligned_subtitle_pairs
            when nil
              # No operations to record
            else
              puts "Handle this! #{ @operations_group_type.inspect }"
            end

            if @operations_group_type
              reset_operations_group!
            end

            # Check if we need to trigger an auto event
            if(tae = @fsm_trigger_auto_event)
              @fsm.trigger!(tae)
              @fsm_trigger_auto_event = nil
            end
          }

          if :idle != @fsm.state
            raise "Uncompleted operation analysis for hunk!"
          end
          collected_operations_groups
        end

        # @param deleted_aligned_subtitles [Array<>]
        # @param added_aligned_subtitles [Array<>]
        # @param hunk_subtitles [Array<Repositext::Subtitle>]
        # @return [Array<Hash>]
        #   {
        #     type: nil, # :left_aligned|:right_aligned|...
        #     subtitle_object: nil, # Repositext::Subtitle, nil
        #     sim_left: [], # [sim<Float>, conf<Float>]
        #     sim_right: [], # [sim<Float>, conf<Float>]
        #     sim_abs: [], # [sim<Float>, conf<Float>]
        #     content_length_change: nil, # Integer from del to add
        #     subtitle_count_change: nil, # Integer from del to add
        #     del: deleted_st, # { content: "word word word", old_linenos: [3,4,5], subtitle_count: 0 } # Hunk's deleted line
        #     add: added_st, # { content: "word word word", old_linenos: [3,4,5]. subtitle_count: 1 } # Hunk's added line
        #     index: Integer # zero based, scoped by hunk
        #   }
        def compute_aligned_subtitle_pairs(
          deleted_aligned_subtitles,
          added_aligned_subtitles,
          hunk_subtitles
        )
          # Compute aligned_subtitle_pairs
          disposable_hunk_subtitles = hunk_subtitles.dup
          aligned_subtitle_pairs = []
          most_recent_existing_subtitle_id = nil # to create temp subtitle ids
          temp_subtitle_offset = 0

          deleted_aligned_subtitles.each_with_index { |deleted_st,idx|
            added_st = added_aligned_subtitles[idx]

            # Compute aligned subtitle pair
            asp = {
              type: nil, # :left_aligned|:right_aligned|...
              subtitle_object: nil, # Repositext::Subtitle, nil
              sim_left: [], # [sim<Float>, conf<Float>]
              sim_right: [], # [sim<Float>, conf<Float>]
              sim_abs: [], # [sim<Float>, conf<Float>]
              content_length_change: nil, # Integer from del to add
              subtitle_count_change: nil, # Integer from del to add
              del: deleted_st, # { content: "word word word", old_linenos: [3,4,5], subtitle_count: 0 } # Hunk's deleted line
              add: added_st, # { content: "word word word", old_linenos: [3,4,5]. subtitle_count: 1 } # Hunk's added line
              index: idx, # [Integer]
            }

            # Assign Subtitle object
            st_obj = case deleted_st[:content].count('@')
            when 0
              # Deleted content contains no subtitles, create dummy added subtitle object
              ::Repositext::Subtitle.new(
                persistent_id: [
                  'tmp-',
                  most_recent_existing_subtitle_id || 'hunk_start',
                  '+',
                  temp_subtitle_offset += 1,
                ].join,
                tmp_attrs: {}
              )
            when 1
              # Use next item in hunk's existing subtitle objects
              temp_subtitle_offset = 0 # reset each time we find existing subtitle
              most_recent_existing_subtitle_id = disposable_hunk_subtitles[0].persistent_id
              disposable_hunk_subtitles.shift
            else
              raise "Handle this: #{ deleted_st.inspect }"
            end
            st_obj.tmp_attrs[:before] = deleted_st[:content].gsub('@', '')
            st_obj.tmp_attrs[:after] = added_st[:content].gsub('@', '')
            asp[:subtitle_object] = st_obj

            # Compute various similarities between deleted and added content
            deleted_sim_text = deleted_st[:content].gsub('@', ' ').unicode_downcase
            added_sim_text = added_st[:content].gsub('@', ' ').unicode_downcase
            asp[:sim_left] = JaccardSimilarityComputer.compute(
              deleted_sim_text,
              added_sim_text,
              30, # look at first 30 chars. This number may require tweaking
              :left
            )
            asp[:sim_right] = JaccardSimilarityComputer.compute(
              deleted_sim_text,
              added_sim_text,
              30, # look at last 30 chars. This number may require tweaking
              :right
            )
            asp[:sim_abs] = JaccardSimilarityComputer.compute(
              deleted_sim_text,
              added_sim_text,
              false # look at all chars, don't truncate
            )
            asp[:content_length_change] = added_sim_text.length - deleted_sim_text.length # neg means text removal
            asp[:subtitle_count_change] = compute_subtitle_count_change(asp)
            asp[:type] = compute_subtitle_pair_type(asp)
            aligned_subtitle_pairs << asp
          }
          aligned_subtitle_pairs
        end

        # @param line_contents [String]
        # @return [Array<Hash>] array of subtitle caption hashes
        def break_line_into_subtitles(line_contents)
          line_contents.split(/(?=@)/).map { |e|
            {
              content: e,
              length: e.length,
              subtitle_count: e.count('@'),
            }
          }
        end

        def compute_subtitle_count_change(al_st_pair)
          (
            al_st_pair[:add][:subtitle_count] || 0 # may be :gap
          ) - (
            al_st_pair[:del][:subtitle_count] || 0 # may be :gap
          )
        end

        def compute_subtitle_pair_type(al_st_pair)
          # check for gap first, so that we can assume presence of content in later checks.
          if 1 == al_st_pair[:subtitle_count_change]
            # Subtitle was added
            :st_added
          elsif -1 == al_st_pair[:subtitle_count_change]
            # Subtitle was removed
            :st_removed
          elsif al_st_pair[:sim_abs].first == 1.0 and al_st_pair[:sim_abs].last > 0.9
            # max absolute similarity, sufficient confidence
            :identical
          elsif al_st_pair[:sim_left].first == 1.0 and al_st_pair[:sim_left].last > 0.9
            # max left similarity, sufficient confidence
            :left_aligned
          elsif al_st_pair[:sim_right].first == 1.0 and al_st_pair[:sim_right].last > 0.9
            # max right similarity, sufficient confidence
            :right_aligned
          else
            :unaligned
          end
        end

        # An FSM to track operations state
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
            :identical,
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

        # Resets state for the operations_group
        def reset_operations_group!
          @operations_group_type = nil
          @operations_group_subtitle_pair_types = []
          @operations_group_aligned_subtitle_pairs = []
        end

        # Computes all subtitle operations for operations_group
        # @param operations_group [Array<Hash>] an array of aligned_subtitle_pairs:
        #   [
        #     {
        #       type: :gap, # :left_aligned|:right_aligned
        #       subtitle_object: [Repositext::Subtitle, nil],
        #       sim_left: [sim<Float>, conf<Float>],
        #       sim_right: [sim<Float>, conf<Float>],
        #       sim_abs: [sim<Float>, conf<Float>],
        #       content_length_change: [Integer], # from del to add
        #       del: {
        #         content: "word word word",
        #         old_linenos: [3,4,5],
        #       }, # Hunk's deleted line
        #       add: {
        #         content: "word word word",
        #         old_linenos: [3,4,5],
        #       } # Hunk's added line
        #       index: [Integer]
        #     }
        #   ]
        # @param previous_subtitle_id [String, Nil]
        # @return [Array<Subtitle::Operation>]
        def compute_operations_for_group(operations_group, previous_subtitle_id)
          # Initialize state variables
          collected_operations = []
          cumulative_text_length_difference = 0
          remaining_subtitle_count_difference = operations_group.inject(0) { |m,e|
            e[:subtitle_count_change]
          }
          prev_st_id = previous_subtitle_id

          # Iterate over each pair and determine subtitle operation
          operations_group.each_with_index { |al_st_pair, idx|
            prev_al_st_pair = idx > 0 ? operations_group[idx - 1] : nil
            next_al_st_pair = idx < (operations_group.length - 1) ? operations_group[idx + 1] : nil
            added_content = al_st_pair[:add][:content]
            deleted_content = al_st_pair[:del][:content]

            case al_st_pair[:type]
            when :left_aligned
              # Contributes no operation itself.
              # Only contributes current subtitle to affected subtitles for next operation.
            when :right_aligned
              # A move, affecting the previous and current subtitles
              op_type = cumulative_text_length_difference < 0 ? :moveLeft : :moveRight
              collected_operations << {
                affectedStids: [prev_al_st_pair, al_st_pair].compact.map { |e| e[:subtitle_object] },
                operationId: [@hunk_index, al_st_pair[:index]].join('-'),
                operationType: op_type,
              }
            when :st_added
              # A split
              aff_stids = [prev_al_st_pair, al_st_pair].compact.map { |e| e[:subtitle_object] }
              collected_operations << {
                affectedStids: aff_stids,
                operationId: [@hunk_index, al_st_pair[:index]].join('-'),
                operationType: :split,
              }
              remaining_subtitle_count_difference -= al_st_pair[:subtitle_count_change]
            when :st_removed
              # A merge
              collected_operations << {
                affectedStids: [prev_al_st_pair, al_st_pair].compact.map { |e| e[:subtitle_object] },
                operationId: [@hunk_index, al_st_pair[:index]].join('-'),
                operationType: :merge,
              }
              remaining_subtitle_count_difference -= al_st_pair[:subtitle_count_change]
            when :unaligned
              # Either a content change if it's the first subtitle in an operations_group, or a move.
              if 0 == idx
                # This is the first subtitle in an operations_group, must be a content change.
                # Nothing to do
              else
                op_type = cumulative_text_length_difference < 0 ? :moveLeft : :moveRight
                collected_operations << {
                  affectedStids: [prev_al_st_pair, al_st_pair].compact.map { |e| e[:subtitle_object] },
                  operationId: [@hunk_index, al_st_pair[:index]].join('-'),
                  operationType: op_type,
                }
              end
            else
              raise "Handle this: #{ al_st_pair }"
            end
            prev_st_id = al_st_pair[:subtitle_object].persistent_id

            # Update state
            cumulative_text_length_difference += al_st_pair[:content_length_change]
          }

          # Consolidate adjacent merges and splits
          consolidatable_operation_types = [:merge, :split]
          consolidated_operations = collected_operations.inject([]) { |m,cur_op|
            prev_op = m.last
            if prev_op.nil? || prev_op[:operationType] != cur_op[:operationType]
              # First operation, or current operation type is different from
              # previous one. Use as is.
              m << cur_op
            elsif (
              consolidatable_operation_types.include?(cur_op[:operationType]) &&
              prev_op[:operationType] == cur_op[:operationType]
            )
              # This is an adjacent split or merge, consolidate with previous
              # operation:
              # * Use previous operation's operationId
              # * Keep operationType
              # * Append last affectedStid (first should already be in previous op)
              first_a_stid, last_a_stid = cur_op[:affectedStids]
              if 2 != cur_op[:affectedStids].length || first_a_stid != prev_op[:affectedStids].last
                raise "Handle this: #{ [prev_op, cur_op].inspect }"
              end
              prev_op[:affectedStids] << last_a_stid
            else
              # Same operationType, however it's not consolidatable. Use as is.
              m << cur_op
            end
            m
          }
          consolidated_operations.map { |operation_attrs|
            Subtitle::Operation.new_from_hash(operation_attrs)
          }
        end

      end

    end
  end
end
