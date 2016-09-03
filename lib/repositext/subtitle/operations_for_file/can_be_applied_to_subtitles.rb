class Repositext
  class Subtitle
    class OperationsForFile

      # Implements methods to apply self to subtitles
      module CanBeAppliedToSubtitles

        # Applies operations to existing_subtitles: Adds or removes subtitles as needed.
        # @param existing_subtitles [Array<Hash>]. Each subtitle must have the
        #     `persistent_id` key. All other keys will be preserved.
        # @return Array<Hash> a copy of the original one with operations applied.
        def apply_to_subtitles(existing_subtitles)
          updated_subtitles = existing_subtitles.dup
          # First we insert any new subtitles (so that their afterStids are still
          # all there as some may get deleted.)
          insert_new_subtitles!(updated_subtitles)
          # Next we handle deletions of subtitles (after inserts have been made
          # that may refer to deleted afterStids)
          delete_subtitles!(updated_subtitles)
          updated_subtitles
        end

        # Adds new subtitles from insert operations into subtitles_container
        # (in place)
        # @param subtitles_container [Array<Hash>]
        def insert_new_subtitles!(subtitles_container)
          insert_and_split_ops.each do |op|
            insert_at_index = compute_insert_at_index(op, subtitles_container)
            # Get all the inserted subtitle ids
            inserted_stids = op.affectedStids.find_all { |e|
              '' == e.tmp_attrs[:before].to_s and '' != e.tmp_attrs[:after].to_s
            }.map(&:persistent_id)
            # Insert subtitle ids into subtitles_container, starting with last
            # so that we can insert them all at the same index.
            inserted_stids.reverse.each { |stid|
              subtitles_container.insert(insert_at_index, { persistent_id: stid })
            }
          end
          true
        end

        # Removes subtitles from delete operations from subtitles_container
        # (in place)
        # @param subtitles_container [Array<Hash>]
        def delete_subtitles!(subtitles_container)
          delete_and_merge_ops.each do |op|
            # Remove subtitle
            op.affectedStids.each { |aff_st|
              next  unless '' == aff_st.tmp_attrs[:after]
              subtitles_container.delete_if { |new_st|
                new_st[:persistent_id] == aff_st.persistent_id
              }
            }
          end
          true
        end

        # Computes the index in updated_subtitles at which to insert a new subtitle.
        # @param op [Subtitle::Operation]
        # @param updated_subtitles [Array<Hash>]
        # @return [Integer] insert_at_index
        def compute_insert_at_index(op, updated_subtitles)
          insert_at_index = case op.operationType
          when 'insert'
            # No matter if op has one or more affectedStids, we only need the
            # first index. All affectedStids will be inserted here in the
            # correct order.
            compute_insert_at_index_given_after_stid(
              op.afterStid,
              updated_subtitles
            )
          when 'split'
            first_st = op.affectedStids.first
            rest_sts = op.affectedStids[1..-1]
            signature_computer = ->(st) {
              '' == st.tmp_attrs[:before] ? :blank : :present
            }
            # Compute before signature of first and unique rest elements
            aff_stid_before_signatures = (
              [signature_computer.call(first_st)] +
              rest_sts.map { |e| signature_computer.call(e) }.uniq
            )
            case aff_stid_before_signatures
            when [:present, :blank]
              # This is a regular split where the original subtitle comes first.
              # Insert new subtitle after original subtitle
              compute_insert_at_index_given_after_stid(
                op.affectedStids.first.persistent_id,
                updated_subtitles
              )
            else
              # This is an unexpected case.
              puts @content_at_file.filename
              p op
              p aff_stid_before_signatures
              raise "Handle unexpected split!"
            end
          else
            raise "Handle this: #{ op.inspect }"
          end
          insert_at_index
        end

        # Returns the insert_at index in updated_subtitles after subtitle with after_stid.
        # @param after_stid [String] the stid to insert after
        # @param updated_subtitles [Array<Hash>] the array to insert into.
        def compute_insert_at_index_given_after_stid(after_stid, updated_subtitles)
          # Insert at beginning of new file
          return 0  if 'new_file' == after_stid

          # Get index of subtitle with after_stid persistent_id in updated_subtitles
          insert_after_index = updated_subtitles.index { |new_st|
            new_st[:persistent_id] == after_stid
          }

          # Ruby's Array#insert method inserts before the given index, so we
          # need to use the index of the next element or -1 if we're at the end.
          insert_at_index = insert_after_index + 1
          if updated_subtitles[insert_at_index].nil?
            # We're at the end of updated_subtitles, insert at end via -1
            insert_at_index = -1
          end
          insert_at_index
        end
      end
    end
  end
end
