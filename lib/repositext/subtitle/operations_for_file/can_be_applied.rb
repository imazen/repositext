class Repositext
  class Subtitle
    class OperationsForFile

      # Implements methods to apply self to subtitles
      module CanBeApplied

        # Applies operations to existing_stids: Adds or removes subtitles as needed.
        # @param existing_stids [Array<Hash>]. Each subtitle must have the
        #     `persistent_id` key. All other keys will be preserved.
        # @return Array<Hash> a copy of the original one with operations applied.
        def apply_to(existing_subtitles)
          new_subtitles = existing_subtitles.dup
          # First we insert any new subtitles (so that their afterStids are still
          # all there as some may get deleted.)
          insert_new_subtitles!(new_subtitles)
          # Next we handle deletions of subtitles (after inserts have been made
          # that may refer to deleted afterStids)
          delete_subtitles!(new_subtitles)
          new_subtitles
        end

        # Applies insert operations to new_subtitles (in place)
        # @param new_subtitles [Array<Hash>]
        def insert_new_subtitles!(new_subtitles)
          insert_and_split_ops.each do |op|
            insert_at_index = compute_insert_at_index(op, new_subtitles)
            # I assume that the inserted persistent id is always the last affectedStid.
            # TODO: Verify this assumption.
            new_stid = op.affectedStids.last.persistent_id
            # Insert subtitle into new_subtitles
            new_subtitles.insert(insert_at_index, { persistent_id: new_stid })
          end
          true
        end

        # Applies delete operations to new_subtitles (in place)
        # @param new_subtitles [Array<Hash>]
        def delete_subtitles!(new_subtitles)
          operations.find_all{ |op|
            %w[delete merge].include?(op.operationType)
          }.each do |op|
            # Remove subtitle
            op.affectedStids.each { |aff_st|
              next  unless '' == aff_st.tmp_attrs[:after]
              new_subtitles.delete_if { |new_st|
                new_st[:persistent_id] == aff_st.persistent_id
              }
            }
          end
          true
        end

        # Computes the index in new_subtitles at which to insert a new subtitle.
        # @param op [Subtitle::Operation]
        # @param new_subtitles [Array<Hash>]
        # @return [Integer] insert_at_index
        def compute_insert_at_index(op, new_subtitles)
          insert_at_index = case op.operationType
          when 'insert'
            # Insert new stid after op#afterStid
            compute_insert_at_index_given_after_stid(
              op.afterStid,
              new_subtitles
            )
            if 1 != op.affectedStids.length
              raise "Handle this: #{ op.inspect }"
            end
          when 'split'
            aff_stid_before_signature = op.affectedStids.map { |st|
              '' == st.tmp_attrs[:before] ? :blank : :present
            }
            case aff_stid_before_signature
            when [:present, :blank]
              # This is a regular split where the original subtitle comes first.
              # Insert new subtitle after original subtitle
              compute_insert_at_index_given_after_stid(
                op.affectedStids.first.persistent_id,
                new_subtitles
              )
            when [:blank, :blank]
              # This is two subsequent splits/insertions.
              # Insert new subtitle after first subtitle (using mapping)
              compute_insert_at_index_given_after_stid(
                op.affectedStids.first.persistent_id,
                new_subtitles
              )
            else
              # This is an odd case, kind of unexpected. I should write a test case for this...
              puts @content_at_file.filename
              p op
              p op.affectedStids
              raise "Handle odd split!"
            end
          else
            raise "Handle this: #{ op.inspect }"
          end
          insert_at_index
        end

        # Returns the insert_at index in new_subtitles after subtitle with after_stid.
        # @param after_stid [String] the stid to insert after
        # @param new_subtitles [Array<Hash>] the array to insert into.
        def compute_insert_at_index_given_after_stid(after_stid, new_subtitles)
          # Insert at beginning of new file
          return 0  if 'new_file' == after_stid

          # Get index of subtitle with after_stid persistent_id in new_subtitles
          insert_after_index = new_subtitles.index { |new_st|
            new_st[:persistent_id] == after_stid
          }

          # Ruby's Array#insert method inserts before the given index, so we
          # need to use the index of the next element or -1 if we're at the end.
          insert_at_index = insert_after_index + 1
          if new_subtitles[insert_at_index].nil?
            # We're at the end of new_subtitles, insert at end via -1
            insert_at_index = -1
          end
          insert_at_index
        end

      end
    end
  end
end
