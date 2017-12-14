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
            include_content_not_inside_a_subtitle: true,
            subtitle_attrs_override: from_subtitles,
            with_content: true
          )
          apply_self_to_foreign_subtitles!(
            foreign_subtitles_with_content,
            to_subtitles
          )
          # Join subtitle fragments into single content string
          r = foreign_subtitles_with_content.map { |e| e.content }.join
          # Clean up subtitle_mark placement
          adjust_stmp_o = Process::Fix::AdjustSubtitleMarkPositions.fix(
            r,
            foreign_content_at_file.language
          )
          if adjust_stmp_o.success?
            # Return string with adjusted subtitle_marks
            adjust_stmp_o.result
          else
            raise "Handle this: #{ adjust_stmp_o.inspect }"
          end

        end

      private

        # Applies self's operations to foreign_subtitles_with_content, makes
        # changes in place.
        # Only insert/split and delete/merge operations change foreign contents.
        # Moves and content_changes are just recorded under the
        # `st_sync_subtitles_to_review` key in the data.json file.
        # @param foreign_subtitles_with_content [Array<Subtitle>]
        # @param to_subtitles [Array<Subtitle>]
        def apply_self_to_foreign_subtitles!(foreign_subtitles_with_content, to_subtitles)
          # First we insert any new subtitles (so that their after_stids are still
          # all there as some may get deleted.)
          insert_new_subtitles_into_foreign_content_at!(
            foreign_subtitles_with_content,
            to_subtitles
          )
          # Next we handle deletions of subtitles (after inserts have been made
          # that may refer to deleted after_stids)
          delete_subtitles_from_foreign_content_at!(foreign_subtitles_with_content)
        end

        # Applies insert operations to foreign_subtitles_with_content (in place)
        # @param foreign_subtitles_with_content [Array<Subtitle>]
        # @param to_subtitles [Array<Subtitle>]
        def insert_new_subtitles_into_foreign_content_at!(foreign_subtitles_with_content, to_subtitles)
          insert_and_split_ops.each do |op|
            insert_after_stid = case op.operation_type
            when 'insert'
              # We use the operation's after_stid attribute
              op.after_stid
            when 'split'
              # We use the first affected_stid
              op.affected_stids.first.persistent_id
            else
              raise "Handle this: #{ op.inspect }"
            end
            insert_after_st = foreign_subtitles_with_content.detect { |e|
              e.persistent_id == insert_after_stid
            }
            insert_after_st_index = foreign_subtitles_with_content.index(insert_after_st)
            insert_at_index = insert_after_st_index + 1
            stid_to_insert = op.affected_stids.last.persistent_id
            st_to_insert = to_subtitles.detect { |e| e.persistent_id == stid_to_insert }
            # For foreign files, we want to treat inserts like splits, i.e.
            # we don't insert any content, we just use the second half of the
            # previous subtitle's content.

            # split contents
            first, second = insert_after_st.content.split_into_two
            insert_after_st.content = first
            st_to_insert.content = ['@', second].join # prefix with subtitle_mark

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
            # We create signature based on whether `after` is empty (indicates deletion).
            signature = op.affected_stids.map { |e| '' == e.tmp_attrs[:after] }
            case op.operation_type
            when 'delete'
              # We may get false `Delete` operations. Because of that, we have a
              # policy that we don't remove any content. Instead we treat it
              # like a merge and add the deleted subtitle's content to the
              # previous one.
              # Verify that affected_stids are what we expect them to be:
              if [true] != signature
                raise "Handle this: signature: #{ signature.inspect }, operation: #{ op.to_hash.inspect }".color(:red)
              end
              deleted_stid = op.affected_stids.first.persistent_id
              retained_st, deleted_st = nil, nil
              foreign_subtitles_with_content.each_cons(2) { |prev_st, cur_st|
                if cur_st.persistent_id == deleted_stid
                  retained_st, deleted_st = prev_st, cur_st
                  break
                end
              }
            when 'merge'
              # Merge contents into first subtitle, delete second st.
              # Make sure that deleted subtitle comes second.
              # NOTE: The subtitle operation may be a compound merge that has more
              # than two affected subtitles. In this case the empty `after` still
              # needs to be at the end. We use #chunk to collapse adjacent identical
              # items in the signature.
              if [false, true] != signature.chunk { |e| e }.map(&:first)
                raise "Handle this: signature: #{ signature.inspect }, operation: #{ op.to_hash.inspect }".color(:red)
              end
              retained_stid, deleted_stid = op.affected_stids.map { |e| e.persistent_id }
              retained_st = foreign_subtitles_with_content.detect { |e| retained_stid == e.persistent_id }
              deleted_st = foreign_subtitles_with_content.detect { |e| deleted_stid == e.persistent_id }
            else
              raise "Handle this: #{ op.inspect }"
            end
            retained_st.content << deleted_st.content.sub(/\A@/, '')
            foreign_subtitles_with_content.delete(deleted_st)
          end
          true
        end

      end
    end
  end
end
