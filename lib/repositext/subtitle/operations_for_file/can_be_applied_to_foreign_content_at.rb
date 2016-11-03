class Repositext
  class Subtitle
    class OperationsForFile

      # Implements methods to apply self to foreign content AT.
      module CanBeAppliedToForeignContentAt

        # Applies operations to foreign content_at file. Returns new contents
        # with updated subtitles as string.
        # @param foreign_content_at_file [RFile::ContentAt]
        # @param from_subtitles [Array<Subtitle>]
        # @param to_subtitles [Array<Subtitle>]
        # @return [String] modified contents of foreign_content_at_file with st ops applied
        def apply_to_foreign_content_at_file(foreign_content_at_file, from_subtitles, to_subtitles)
          foreign_subtitles_with_content = foreign_content_at_file.subtitles(
            true,
            from_subtitles
          )
          apply_self_to_foreign_subtitles!(
            foreign_subtitles_with_content,
            to_subtitles
          )
          # Join subtitle fragments into single content string
          foreign_subtitles_with_content.map { |e| e.content }.join
        end

      private

        # Applies self's operations to foreign_subtitles_with_content, makes
        # changes in place.
        # @param foreign_subtitles_with_content [Array<Subtitle>]
        # @param to_subtitles [Array<Subtitle>]
        def apply_self_to_foreign_subtitles!(foreign_subtitles_with_content, to_subtitles)
          # First we insert any new subtitles (so that their afterStids are still
          # all there as some may get deleted.)
          insert_new_subtitles_into_foreign_content_at!(
            foreign_subtitles_with_content,
            to_subtitles
          )
          # Next we handle deletions of subtitles (after inserts have been made
          # that may refer to deleted afterStids)
          delete_subtitles_from_foreign_content_at!(foreign_subtitles_with_content)
        end

        # Applies insert operations to foreign_subtitles_with_content (in place)
        # @param foreign_subtitles_with_content [Array<Subtitle>]
        # @param to_subtitles [Array<Subtitle>]
        def insert_new_subtitles_into_foreign_content_at!(foreign_subtitles_with_content, to_subtitles)
          insert_and_split_ops.each do |op|
            insert_after_stid = op.affectedStids.first.persistent_id
            insert_after_st = foreign_subtitles_with_content.detect { |e|
              e.persistent_id == insert_after_stid
            }
            insert_after_st_index = foreign_subtitles_with_content.index(insert_after_st)
            insert_at_index = insert_after_st_index + 1
            stid_to_insert = op.affectedStids.last.persistent_id
            st_to_insert = to_subtitles.detect { |e| e.persistent_id == stid_to_insert }
            case op.operationType
            when 'insert'
              # nothing to do
            when 'split'
              # split contents
              first, second = insert_after_st.content.split_into_two
              insert_after_st.content = first
              st_to_insert.content = ['@', second].join # prefix with subtitle_mark
            else
              raise "Handle this: #{ op.inspect }"
            end
            foreign_subtitles_with_content.insert(
              insert_at_index,
              st_to_insert
            )
          end
          true
        end

        # Applies delete operations to foreign_subtitles_with_content (in place)
        # @param foreign_subtitles_with_content [Array<Subtitle>]
        def delete_subtitles_from_foreign_content_at!(foreign_subtitles_with_content)
          delete_and_merge_ops.each do |op|
            # Make sure that deleted subtitle comes second. We create signature
            # based on whether `after` is empty (indicates deletion).
            signature = op.affectedStids.map { |e| '' == e.tmp_attrs[:after] }
            # NOTE: The subtitle operation may be a compound merge that has more
            # than two affected subtitles. In this case the empty `after` still
            # needs to be at the end. We use #chunk to collapse adjacent identical
            # items in the signature.
            if [false, true] != signature.chunk { |e| e }.map(&:first)
              raise "Handle this: signature: #{ signature.inspect }, operation: #{ op.to_hash.inspect }".color(:red)
            end
            retained_stid, deleted_stid = op.affectedStids.map { |e| e.persistent_id }
            retained_st = foreign_subtitles_with_content.detect { |e| retained_stid == e.persistent_id }
            deleted_st = foreign_subtitles_with_content.detect { |e| deleted_stid == e.persistent_id }
            case op.operationType
            when 'delete'
              # nothing to do
            when 'merge'
              # merge contents
              retained_st.content << deleted_st.content.sub(/\A@/, '')
            else
              raise "Handle this: #{ op.inspect }"
            end
            foreign_subtitles_with_content.delete(deleted_st)
          end
          true
        end

      end
    end
  end
end
