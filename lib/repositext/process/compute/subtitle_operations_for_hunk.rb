class Repositext
  class Process
    class Compute

=begin

Data types used in this file
----------------------------

* SubtitleOperationsForFile::Hunk
      Object #line
        Renders HunkLine objects: #line_origin, #content, #old_linenos

* PerOriginLineGroup
      {
        line_origin: :addition,
        content: 'word word\nword word\nword',
        old_linenos: [12,13,14]
      }

* SanitizedPerOriginLineGroups: Array with two PerOriginLineGroup items. One for
  :deletion and one for :addition:
      [<PerOriginLineGroup>, <PerOriginLineGroup>]

* AlignedSubtitle: A hash describing one subtitle in an aligned pair.
  For a gap:
      { :type=>:gap, :content=>"", :length=>0 }
  For a subtitle:
      {
        :content => "word word word ...",
        :length => 77,
        :subtitle_count => 1
      }

* AlignedSubtitlePair: A hash describing two aligned subtitles in the hunk.
      {
        type: <:left_aligned|:right_aligned|:st_added...>
        subtitle_object: <# Repositext::Subtitle ...>
        sim_left: [sim<Float>, conf<Float>]
        sim_right: [sim<Float>, conf<Float>]
        sim_abs: [sim<Float>, conf<Float>]
        content_length_change: <Integer from del to add>
        subtitle_count_change: <Integer from del to add>
        del: left item of pair (Hunk's deleted line)
             e.g. { content: "word word word", old_linenos: [3,4,5], subtitle_count: 0 }
        add: right item of pair (Hunk's added line)
             e.g. { content: "word word word", old_linenos: [3,4,5]. subtitle_count: 1 }
        index: <Integer> index of aligned st pair in hunk
        first_in_hunk: Boolean, true if asp is first in hunk
        last_in_hunk: Boolean, true if aps is last in hunk
      }

Method structure of this file
-----------------------------

public

  def initialize
    reset_operations_group!
    init_fsm

  def compute
    compute_raw_per_origin_line_groups
    sanitize_per_origin_line_groups
    compute_subtitle_operations_for_sanitized_polgs

protected

  def compute_raw_per_origin_line_groups

  def compute_subtitle_operations_for_sanitized_polgs
    break_line_into_subtitles
    compute_hunk_aligned_subtitle_pairs
    detect_pure_insertions_or_deletions
    extract_and_group_asps_with_st_ops
    compute_operations

  def break_line_into_subtitles

  def compute_hunk_aligned_subtitle_pairs
    JaccardSimilarityComputer.compute
    compute_subtitle_count_change
    compute_subtitle_pair_type

  def compute_subtitle_count_change

  def compute_subtitle_pair_type

  def extract_and_group_asps_with_st_ops
    reset_operations_group!

  def init_fsm

  def reset_operations_group!

  def compute_operations
    compute_operations_for_asp_group_of_1
    compute_operations_for_asp_group_of_2
    compute_operations_for_complex_asp_group

  def detect_pure_insertions_or_deletions

  def compute_operations_for_asp_group_of_1

  def compute_operations_for_asp_group_of_2

  def compute_operations_for_complex_asp_group
    detect_pure_insertions_or_deletions
    compute_ins_del_map_for_asp_group

  def compute_ins_del_map_for_asp_group

=end

      # Computes subtitle operations for a hunk
      class SubtitleOperationsForHunk

        # Instantiates a new compute instance for a Hunk.
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

        # Computes subtitle operations for Hunk.
        # @return [Hash]
        #     {
        #       last_stid: String,
        #       subtitle_operations: [Array<Subtitle::Operation>]
        #     }
        def compute
          raw_per_origin_line_groups = compute_raw_per_origin_line_groups(@hunk)
          sanitized_polgs = sanitize_per_origin_line_groups(raw_per_origin_line_groups)
          r = compute_subtitle_operations_for_sanitized_polgs(
            @content_at_lines_with_subtitles,
            sanitized_polgs
          )
        end

      protected

        # Takes hunk and collapses hunk lines into groups that share common
        # line_origins (:deleted and :added).
        # Concatenates :content and :old_line_nos of adjacent lines with same
        # line_origin.
        # @param hunk [SubtitleOperationsForFile::Hunk]
        # @return [Array<PerOriginLineGroup>]
        def compute_raw_per_origin_line_groups(hunk)
          polgs = []
          current_origin = nil
          hunk.lines.each { |line|
            if current_origin != line.line_origin
              # Start new group
              polgs << { line_origin: line.line_origin, content: '', old_linenos: [] }
              current_origin = line.line_origin
            end
            # Append line attrs to current group
            polgs.last[:content] << line.content
            polgs.last[:old_linenos] << line.old_lineno
          }
          polgs
        end

        # Sanitizes raw_per_origin_line_groups to a standard format consisting
        # of exactly two elements: :deletion and :addition.
        # @param raw_per_origin_line_groups [Array<PerOriginLineGroup>]
        # @return [SanitizedPerOriginLineGroups]
        def sanitize_per_origin_line_groups(raw_per_origin_line_groups)
          hunk_line_origin_signature = raw_per_origin_line_groups.map { |e|
            e[:line_origin]
          }
          case hunk_line_origin_signature
          when [:addition]
            # Just addition. We create an empty :deletion
            # We set :content to "\n" so that it matches the consistency
            # check in #compute_subtitle_operations_for_sanitized_polgs
            [
              { line_origin: :deletion, content: "\n", old_linenos: [] },
              raw_per_origin_line_groups[0],
            ]
          when [:deletion]
            # Just deletion. We create an empty :addition
            # We set :content to "\n" so that it matches the consistency
            # check in #compute_subtitle_operations_for_sanitized_polgs
            [
              raw_per_origin_line_groups[0],
              { line_origin: :addition, content: "\n", old_linenos: [] },
            ]
          when [:deletion, :addition]
            # Return as is
            raw_per_origin_line_groups
          when [:deletion, :addition, :eof_newline_removed]
            # We resolve the eof_newline_removed by adding a newline to :addition's content
            [
              raw_per_origin_line_groups[0],
              raw_per_origin_line_groups[1].tap { |e| e[:content] << "\n" },
            ]
          when [:deletion, :eof_newline_added, :addition]
            # We resolve the eof_newline_added by adding a newline to :deletion's content
            [
              raw_per_origin_line_groups[0].tap { |e| e[:content] << "\n" },
              raw_per_origin_line_groups[1],
            ]
          else
            puts "per_origin_line_groups:"
            p raw_per_origin_line_groups
            puts "hunk:"
            p @hunk
            raise "Handle this"
          end
        end

        # Computes subtitle operations for sanitized per_origin_line_groups.
        # @param content_at_lines_with_subtitles [Array<Hash>]
        #   {
        #     content: "the content",
        #     line_no: 42,
        #     subtitles: [<Subtitle>, ...],
        #   }
        # @param per_origin_line_groups [SanitizedPerOriginLineGroups]
        # @return [Hash]
        #     { last_stid: String, subtitle_operations: [Array<Subtitle::Operation>] }
        def compute_subtitle_operations_for_sanitized_polgs(
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
          hunk_aligned_subtitle_pairs = compute_hunk_aligned_subtitle_pairs(
            deleted_aligned_subtitles,
            added_aligned_subtitles,
            hunk_subtitles
          )

          # Use hunk's last stid or previous hunk's last stid
          last_stid = ((ls = hunk_subtitles.last) and ls.persistent_id) || @previous_stid

          # Return early if all operations in hunk are insertions or deletions
          if(
            ops = detect_pure_insertions_or_deletions(
              hunk_aligned_subtitle_pairs,
              last_stid
            )
          ).any?
            return { subtitle_operations: ops, last_stid: last_stid }
          end

          # Otherwise do the more involved operations analysis
          asp_groups_with_st_ops = extract_and_group_asps_with_st_ops(hunk_aligned_subtitle_pairs)
          collected_operations = compute_operations(asp_groups_with_st_ops)

          {
            subtitle_operations: collected_operations,
            last_stid: last_stid,
          }
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

        # Computes all aligned_subtitle_pairs (asps) for hunk. Only some of the
        # asps will be affected by subtitle operations.
        # @param deleted_aligned_subtitles [Array<AlignedSubtitle>]
        # @param added_aligned_subtitles [Array<AlignedSubtitle>]
        # @param hunk_subtitles [Array<Repositext::Subtitle>]
        # @return [Array<AlignedSubtitlePair>]
        def compute_hunk_aligned_subtitle_pairs(
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
              type: nil, # :left_aligned|:right_aligned|:st_added...
              subtitle_object: nil, # Repositext::Subtitle, nil
              sim_left: [], # [sim<Float>, conf<Float>]
              sim_right: [], # [sim<Float>, conf<Float>]
              sim_abs: [], # [sim<Float>, conf<Float>]
              content_length_change: nil, # Integer from del to add
              subtitle_count_change: nil, # Integer from del to add
              del: deleted_st, # left item in pair (Hunk's deletion) { content: "word word word", old_linenos: [3,4,5], subtitle_count: 0 } # Hunk's deleted line
              add: added_st, # right item in pair (Hunk's addition) { content: "word word word", old_linenos: [3,4,5]. subtitle_count: 1 } # Hunk's added line
              index: idx, # index of asp in hunk [Integer]
              first_in_hunk: 0 == idx, # Boolean
              last_in_hunk: deleted_aligned_subtitles.length == idx + 1, # Boolean
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

        # Returns difference in subtitles from :del to :add in al_st_pair.
        # @param al_st_pair [AlignedSubtitlePair]
        # @return [Integer]
        def compute_subtitle_count_change(al_st_pair)
          (
            al_st_pair[:add][:subtitle_count] || 0 # may be :gap
          ) - (
            al_st_pair[:del][:subtitle_count] || 0 # may be :gap
          )
        end

        # Returns nature of al_st_pair.
        # @param al_st_pair [AlignedSubtitlePair]
        # @return [Symbol]
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

        # Takes all the hunk's aligned_subtitle_pairs, extracts the ones that
        # contain subtitle operations and groups them according to various
        # boundaries. Uses a state_machine to do so.
        # Returns an Array of Arrays of AlignedSubtitlePair items.
        # @param aligned_subtitle_pairs [Array<AlignedSubtitlePair>]
        # @return [Array<Array<AlignedSubtitlePair>>]
        def extract_and_group_asps_with_st_ops(aligned_subtitle_pairs)
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
              al_st_pair[:last_in_hunk] ||
              [:left_aligned, :identical].include?(next_al_st_pair[:type])
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
            raise "Uncompleted operation analysis for hunk!"
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

        # Resets state when starting with a new operations_group.
        def reset_operations_group!
          @operations_group_type = nil
          @operations_group_subtitle_pair_types = []
          @operations_group_aligned_subtitle_pairs = []
        end

        # Takes groups of aligned subtitle pairs and computes their subtitle
        # operations.
        # @param asp_groups [Array<Array<AlignedSubtitlePair>>]
        # @return [Array<Subtitle::Operation>]
        def compute_operations(asp_groups)
          collected_operations = []
          previous_subtitle_object = nil
          asp_groups.each { |asp_group|
            # Get previous stid from previous hunk or previous subtitle object
            prev_stid = if previous_subtitle_object.nil?
              @previous_stid
            else
              previous_subtitle_object.persistent_id
            end

            # Return early if all operations in asp_group are insertions or deletions
            if(ops = detect_pure_insertions_or_deletions(asp_group, prev_stid)).any?
              collected_operations += ops
              next
            end

            case asp_group.length
            when 0
              # No aligned_subtitle_pairs in group. Raise exception!
              raise "handle this!"
            when 1
              # One aligned_subtitle_pair in group
              collected_operations += compute_operations_for_asp_group_of_1(
                asp_group,
                prev_stid
              )
            when 2
              # Two aligned_subtitle_pairs in group
              collected_operations += compute_operations_for_asp_group_of_2(
                asp_group,
                prev_stid
              )
            else
              # Three or more aligned_subtitle_pairs in group
              collected_operations += compute_operations_for_complex_asp_group(
                asp_group,
                prev_stid
              )
            end
            #
            previous_subtitle_object = asp_group.last[:subtitle_object]
          }
          collected_operations
        end

        # Checks if the aligned_subtitle_pairs contain only insertions or
        # deletions and returns the operations. Otherwise it returns an empty
        # array.
        # NOTE: This gets called twice: Once with all hunk asps and once with
        # each asp_group.
        # @param aligned_subtitle_pairs [Array<AlignedSubtitlePair>]
        # @param previous_subtitle_id [String, Nil]
        # @return [Array<Subtitle::Operation>]
        def detect_pure_insertions_or_deletions(aligned_subtitle_pairs, previous_subtitle_id)
          if(
            aligned_subtitle_pairs.any? { |e| :st_added == e[:type] } &&
            aligned_subtitle_pairs.all? { |e| [:st_added, :identical].include?(e[:type]) }
          )
            # Contains at least one :st_added, and maybe some :identical.
            # This is an insertion.
            after_stid = previous_subtitle_id
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
          elsif(
            aligned_subtitle_pairs.any? { |e| :st_removed == e[:type] } &&
            aligned_subtitle_pairs.all? { |e| [:st_removed, :identical].include?(e[:type]) }
          )
            # Contains at least one :st_removed, and maybe some :identical.
            # This is a deletion.
            after_stid = previous_subtitle_id
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
          aligned_subtitle_pair = asp_group.first
          asp_group_subtitle_objects = asp_group.map { |e| e[:subtitle_object] }

          case aligned_subtitle_pair[:type]
          when :left_aligned
            # Content change. We don't track this.
            []
          when :right_aligned
            # Content change. We don't track this.
            []
          when :st_added
            [
              Subtitle::Operation.new_from_hash(
                affectedStids: asp_group_subtitle_objects,
                operationId: [@hunk_index, aligned_subtitle_pair[:index]].join('-'),
                operationType: :insert,
                afterStid: previous_subtitle_id,
              )
            ]
          when :st_removed
            [
              Subtitle::Operation.new_from_hash(
                affectedStids: asp_group_subtitle_objects,
                operationId: [@hunk_index, aligned_subtitle_pair[:index]].join('-'),
                operationType: :delete,
                afterStid: previous_subtitle_id,
              )
            ]
          when :unaligned
            # Content change. We don't track this.
            []
          else
            raise "Handle this: #{ aligned_subtitle_pair.inspect }"
          end
        end

        # Computes subtitle operations for asp_group with two aligned subtitle
        # pairs.
        # @param asp_group [Array<AlignedSubtitlePair>]
        # @param previous_subtitle_id [String, Nil]
        # @return [Array<Subtitle::Operation>]
        def compute_operations_for_asp_group_of_2(asp_group, previous_subtitle_id)
          st_added_count = asp_group.count { |e| :st_added == e[:type] }
          st_removed_count = asp_group.count { |e| :st_removed == e[:type] }
          gap_count = st_added_count + st_removed_count
          asp_group_subtitle_objects = asp_group.map { |e| e[:subtitle_object] }
          collected_operations = []
          prev_st_id = previous_subtitle_id

          case gap_count
          when 0
            # No gaps, it's a move. Let's find out which direction
            op_type = if asp_group[0][:content_length_change] < 0
              # First pair's content got shorter => move left
              :moveLeft
            else
              # First pair's content got longer => move right
              :moveRight
            end
            collected_operations << Subtitle::Operation.new_from_hash(
              affectedStids: asp_group_subtitle_objects,
              operationId: [@hunk_index, asp_group[0][:index]].join('-'),
              operationType: op_type,
            )
          when 1
            # One gap, it's a merge/delete/split/insert. Let's find out which.
            pair_with_gap = asp_group.detect { |e| 0 != e[:subtitle_count_change] }
            if 1 == st_added_count
              # a subtitle was added => split/insert. Let's find out which:
              if pair_with_gap[:first_in_hunk]
                # It's an insert
                collected_operations << Subtitle::Operation.new_from_hash(
                  affectedStids: [pair_with_gap[:subtitle_object]],
                  operationId: [@hunk_index, pair_with_gap[:index]].join('-'),
                  operationType: :insert,
                )
              else
                # It's a split
                collected_operations << Subtitle::Operation.new_from_hash(
                  affectedStids: asp_group_subtitle_objects,
                  operationId: [@hunk_index, pair_with_gap[:index]].join('-'),
                  operationType: :split,
                )
              end
            elsif 1 == st_removed_count
              # a subtitle was removed => merge/delete. Let's find out which:
              if pair_with_gap[:first_in_hunk]
                # It's a delete
                collected_operations << Subtitle::Operation.new_from_hash(
                  affectedStids: [pair_with_gap[:subtitle_object]],
                  operationId: [@hunk_index, pair_with_gap[:index]].join('-'),
                  operationType: :delete,
                )
              else
                # It's a merge
                collected_operations << Subtitle::Operation.new_from_hash(
                  affectedStids: asp_group_subtitle_objects,
                  operationId: [@hunk_index, pair_with_gap[:index]].join('-'),
                  operationType: :merge,
                )
              end
            else
              raise "Handle this: #{ asp_group.inspect }"
            end
          when 2
            # Two gaps, it's an insertion or deletion. Let's find out which.
            if 2 == st_added_count
              # Two subtitles were added => insert
              asp_group.each { |al_st_pair|
                collected_operations << Subtitle::Operation.new_from_hash(
                  affectedStids: [al_st_pair[:subtitle_object]],
                  operationId: [@hunk_index, al_st_pair[:index]].join('-'),
                  operationType: :insert,
                  afterStid: prev_st_id
                )
                prev_st_id = al_st_pair[:subtitle_object].persistent_id
              }
            elsif 2 == st_removed_count
              # Two subtitles were removed => delete
              asp_group.each { |al_st_pair|
                collected_operations << Subtitle::Operation.new_from_hash(
                  affectedStids: [al_st_pair[:subtitle_object]],
                  operationId: [@hunk_index, al_st_pair[:index]].join('-'),
                  operationType: :delete,
                  afterStid: prev_st_id
                )
                prev_st_id = al_st_pair[:subtitle_object].persistent_id
              }
            else
              # Unexpected change in subtitles
              raise "Handle this: #{ asp_group.inspect }"
            end
          else
            # Unexpected gap count
            raise "Handle this: #{ asp_group.inspect }"
          end
          collected_operations
        end

        # Computes all subtitle operations for a complex asp_group with more
        # than 2 aligned subtitle pairs.
        # @param asp_group [Array<AlignedSubtitlePair>]
        # @param previous_subtitle_id [String, Nil]
        # @return [Array<Subtitle::Operation>]
        def compute_operations_for_complex_asp_group(asp_group, previous_subtitle_id)
          # Initialize state variables
          collected_operations = []
          running_text_length_difference = 0
          total_text_length_difference = asp_group.inject(0) { |m,al_st_pair|
            m += al_st_pair[:content_length_change]
            m
          }
          start_text_length = asp_group.inject(0) { |m,al_st_pair|
            m += al_st_pair[:del][:content].length
            m
          }
          text_change_ratio = (
            start_text_length / (start_text_length + total_text_length_difference.abs).to_f
          )
          remaining_subtitle_count_difference = asp_group.inject(0) { |m,al_st_pair|
            m += al_st_pair[:subtitle_count_change]
            m
          }
          prev_st_id = previous_subtitle_id

          # Compute ins_del_map to detect inserts and deletes at hunk boundaries.
          # These can be caused by subtitles being moved from one paragraph
          # to an adjacent one.
          ins_del_map = compute_ins_del_map_for_asp_group(asp_group)
          # Iterate over each pair and determine subtitle operation
          asp_group.each_with_index { |al_st_pair, idx|
            prev_al_st_pair = idx > 0 ? asp_group[idx - 1] : nil
            next_al_st_pair = idx < (asp_group.length - 1) ? asp_group[idx + 1] : nil
            added_content = al_st_pair[:add][:content]
            deleted_content = al_st_pair[:del][:content]

            case al_st_pair[:type]
            when :left_aligned
              # Contributes no operation itself.
              # Only contributes current subtitle to affected subtitles for next operation.
            when :right_aligned
              # A move, affecting the previous and current subtitles.
              collected_operations << {
                affectedStids: [prev_al_st_pair, al_st_pair].compact.map { |e| e[:subtitle_object] },
                operationId: [@hunk_index, al_st_pair[:index]].join('-'),
                operationType: running_text_length_difference < 0 ? :moveLeft : :moveRight,
              }
            when :st_added
              # A split or an insert, depending on ins_del_map.
              if ins_del_map[idx]
                # This is an insert
                collected_operations << {
                  affectedStids: [al_st_pair[:subtitle_object]],
                  operationId: [@hunk_index, al_st_pair[:index]].join('-'),
                  operationType: :insert,
                  afterStid: prev_st_id,
                }
              else
                # This is a split, affects the previous and current subtitles.
                collected_operations << {
                  affectedStids: [prev_al_st_pair, al_st_pair].compact.map { |e| e[:subtitle_object] },
                  operationId: [@hunk_index, al_st_pair[:index]].join('-'),
                  operationType: :split,
                }
              end
              remaining_subtitle_count_difference -= al_st_pair[:subtitle_count_change]
            when :st_removed
              # A merge or an insert, depending on ins_del_map.
              if ins_del_map[idx]
                # A delete
                collected_operations << {
                  affectedStids: [al_st_pair[:subtitle_object]],
                  operationId: [@hunk_index, al_st_pair[:index]].join('-'),
                  operationType: :delete,
                  afterStid: prev_st_id,
                }
              else
                # A merge, affecting the previous and current subtitles.
                collected_operations << {
                  affectedStids: [prev_al_st_pair, al_st_pair].compact.map { |e| e[:subtitle_object] },
                  operationId: [@hunk_index, al_st_pair[:index]].join('-'),
                  operationType: :merge,
                }
              end
              remaining_subtitle_count_difference -= al_st_pair[:subtitle_count_change]
            when :unaligned
              # Either a content change if it's the first subtitle in an asp_group, or a move.
              if 0 == idx
                # This is the first subtitle in an asp_group, must be a content change.
                # Nothing to do
              else
                # A move, affecting the previous and current subtitles.
                collected_operations << {
                  affectedStids: [prev_al_st_pair, al_st_pair].compact.map { |e| e[:subtitle_object] },
                  operationId: [@hunk_index, al_st_pair[:index]].join('-'),
                  operationType: running_text_length_difference < 0 ? :moveLeft : :moveRight,
                }
              end
            else
              raise "Handle this: #{ al_st_pair }"
            end
            prev_st_id = al_st_pair[:subtitle_object].persistent_id

            # Update state
            running_text_length_difference += al_st_pair[:content_length_change]
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

        # Returns a map of al_st_pairs that represent either inserts or deletes.
        # They are detected by contiguous runs of :st_added/:st_removed at the hunk
        # boundaries. Example: [:st_added, :st_added, :st_added, :right_aligned]
        # or [:left_aligned, :st_removed, :st_removed, :st_removed]
        def compute_ins_del_map_for_asp_group(asp_group)
          ins_del_types = [:st_added, :st_removed]
          ins_del_map = asp_group.map { |_| false } # initialize with all false

          # Quick check for asp_groups that don't have any ins/del candidates.
          first_asp = asp_group.first
          last_asp = asp_group.last
          if(
            !(first_asp[:first_in_hunk] || last_asp[:last_in_hunk]) ||
            !(ins_del_types.include?(first_asp[:type]) || ins_del_types.include?(last_asp[:type]))
          )
            # Early exit
            return ins_del_map
          end

          # More expensive check
          asp_group_chunked_by_type = asp_group.chunk { |asp| asp[:type] }.to_a
          # This returns the following data structure for [:st_added, :st_added, :unaligned]:
          # [[:st_added, [:st_added, :st_added]], [:unaligned, [:unaligned]]]

          # Handle leading ins/dels
          asp_type, asp_instances = asp_group_chunked_by_type.first
          asp_instances_count = asp_instances.count
          if(
            asp_instances.first[:first_in_hunk] &&
            ins_del_types.include?(asp_type)
          )
            # We got at least one ins/del candidate, mark all
            max_idx = asp_instances_count - 1
            ins_del_map.each_with_index { |e, idx| ins_del_map[idx] ||= idx <= max_idx }
          end

          # Handle trailing ins/dels
          asp_type, asp_instances = asp_group_chunked_by_type.last
          asp_instances_count = asp_instances.count
          if(
            asp_instances.last[:last_in_hunk] &&
            ins_del_types.include?(asp_type) &&
            asp_instances_count > 1
          )
            # We got at least one ins/del candidate, mark all but first
            min_idx = (ins_del_map.length + 1) - asp_instances_count
            ins_del_map.each_with_index { |e, idx| ins_del_map[idx] ||= idx >= min_idx }
          end
          ins_del_map
        end

      end
    end
  end
end
