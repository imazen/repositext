class Repositext
  class Process
    class Compute
      class SubtitleOperationsForFile
        module ComputeSubtitleAttrs

          def compute_subtitle_attrs_from(content_at_file_to, from_git_commit)
            content_at_file_from = content_at_file_to.as_of_git_commit(
              from_git_commit
            )
            stm_csv_file_to = content_at_file_to.corresponding_subtitle_markers_csv_file
            stm_csv_file_from = stm_csv_file_to.as_of_git_commit(
              from_git_commit
            )
            st_attrs_with_content_only = convert_content_at_to_subtitle_attrs(
              content_at_file_from.contents
            )
            enrich_st_attrs_from(
              st_attrs_with_content_only,
              stm_csv_file_from.subtitles
            )
          end

          def compute_subtitle_attrs_to(content_at_file_to)
            convert_content_at_to_subtitle_attrs(
              content_at_file_to.contents
            )
          end

        private

          # Converts a content AT string into an array of subtitle attrs.
          # @param conten_at [String]
          # @return [Array<SubtitleAttrs>]
          def convert_content_at_to_subtitle_attrs(content_at)
            doc = Kramdown::Document.new(content_at, :input => 'KramdownRepositext')
            subtitle_export_text = doc.to_subtitle
            st_index = -1
            subtitle_export_text.lines.map { |e|
              next []  if e !~ /\A@/
              next []  if '' == e.strip

              para_sts = e.split('@').map { |f|
                next nil  if '' == f
                f.sub!(/\A\d+\s{4}(?!\s)(.*)/, '\1') # remove paragraph numbers
                f.sub!(/\n\z/, '') # remove trailing newlines
                # Compute content for similarity computation:
                content_sim = f.gsub(/[^[:alnum:]]+/, ' ') # Remove everything except letters, numbers, and space
                               .strip
                               .unicode_downcase
                {
                  content: f,
                  content_sim: content_sim,
                  subtitle_count: 1,
                  index: st_index += 1,
                  repetitions: StringComputations.repetitions(content_sim),
                }
              }.compact
              para_sts.first[:first_in_para] = true
              para_sts.last[:last_in_para] = true
              para_sts
            }.flatten
          end

          # Merges subtitle ids and record ids from STM CSV file into st_attrs.
          # @param st_attrs_list [Array<SubtitleAttrs>]
          # @param st_objects [Array<Subtitle>]
          # @return [Array<SubtitleAttrs>]
          def enrich_st_attrs_from(st_attrs_list, st_objects)
            if st_attrs_list.length != st_objects.length
              pp st_attrs_list
              pp st_objects
              raise(ArgumentError.new("Mismatch in counts: st_attrs_list: #{ st_attrs_list.length }, st_objects: #{ st_objects.length }"))
            end

            if st_objects.any? { |st| st.persistent_id.nil? }
              raise("Encountered subtitle with nil persistent_id!")
            end

            r = []
            st_attrs_list.each_with_index { |st_attrs, idx|
              st_obj = st_objects[idx]
              r << st_attrs.merge({
                persistent_id: st_obj.persistent_id,
                record_id: st_obj.record_id,
              })
            }
            r
          end
        end
      end
    end
  end
end
