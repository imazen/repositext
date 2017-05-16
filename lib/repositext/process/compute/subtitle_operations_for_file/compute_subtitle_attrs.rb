class Repositext
  class Process
    class Compute
      class SubtitleOperationsForFile
        # Namespace for methods related to computing individual subtitles' attributes
        module ComputeSubtitleAttrs

          class MismatchingSubtitleCountsError < ::StandardError; end
          class EncounteredNilStidError < ::StandardError; end

          # @param content_at_file [RFile::ContentAt]
          # @param from_git_commit [String]
          def compute_subtitle_attrs_from(content_at_file, from_git_commit)
            # Note: It's ok to check out file as of `from_git_commit` as Content
            # AT files are not affected by st sync operations.
            content_at_file_from = content_at_file.as_of_git_commit(
              from_git_commit
            )
            st_attrs_with_content_only = convert_content_at_to_subtitle_attrs(
              content_at_file_from.contents
            )
            # Note: STM CSV files need to be checked out at_child_or_ref after
            # the sync reference commit! :at_child_or_ref loads file contents
            # at ref_commit if there is no child commit affecting the given file.
            stm_csv_file = content_at_file.corresponding_subtitle_markers_csv_file
            stm_csv_file_from = stm_csv_file.as_of_git_commit(
              from_git_commit,
              :at_child_or_ref
            )
            enrich_st_attrs(
              st_attrs_with_content_only,
              stm_csv_file_from.subtitles
            )
          end

          # @param content_at_file_to [RFile::ContentAt]
          # @param to_git_commit [String]
          # @param execution_context [Symbol] one of :compute_new_st_ops or :recompute_existing_st_ops
          def compute_subtitle_attrs_to(content_at_file_to, to_git_commit, execution_context)
            st_attrs_with_content_only = convert_content_at_to_subtitle_attrs(
              content_at_file_to.contents
            )

            # Uncomment this code to collect statistics related to subtitles.
            # st_attrs_with_content_only.each { |e|
            #   hkey = e[:content].to_s.length
            #   $repositext_subtitle_length_distribution[hkey] += 1
            # }

            case execution_context
            when :compute_new_st_ops
              # This is part of st_sync, we use st_attrs_with_content_only.
              # We ignore anything in the corresponding STM CSV file.
              st_attrs_with_content_only
            when :recompute_existing_st_ops
              # This is part of a recomputation of existing st_ops, e.g., as
              # part of a table release. We enrich the st_attrs with stids
              # from the corresponding STM CSV file.
              # Note: STM CSV files need to be checked out at a child commit after
              # the ref_commit if that commit exists and affects the file in question.
              # Otherwise we use the contents as of the ref_commit.
              stm_csv_file = content_at_file_to.corresponding_subtitle_markers_csv_file
              stm_csv_file_to = stm_csv_file.as_of_git_commit(
                to_git_commit,
                :at_child_or_ref
              )
              enrich_st_attrs(st_attrs_with_content_only, stm_csv_file_to.subtitles)
            else
              raise "Handle this: #{ execution_context.inspect }"
            end
          end

        private

          # Converts a content AT string into an array of subtitle attrs.
          # @param content_at [String]
          # @return [Array<SubtitleAttrs>]
          def convert_content_at_to_subtitle_attrs(content_at)
            doc = Kramdown::Document.new(
              content_at,
              input: 'KramdownRepositext',
              include_record_ids: true
            )
            subtitle_export_text = doc.to_subtitle

            st_index = -1
            para_index = -1
            # rid_regex is synced with Kramdown::Converter::Subtitle#convert
            rid_regex = /\srid-([[:alnum:]]+)$/
            subtitle_export_text.lines.map { |e|
              next []  if e !~ /\A@/
              next []  if '' == e.strip
              para_index += 1
              # Capture and remove record_id from end of line
              para_record_id = e.match(rid_regex)[1]
              e.sub!(rid_regex, '')

              para_sts = e.split('@').map { |f|
                next nil  if '' == f
                f.sub!(/\A\d+\s{4}(?!\s)(.*)/, '\1') # remove paragraph numbers
                # Compute content for similarity computation:
                content_sim = f.gsub(/[^[:alnum:]]+/, ' ') # Remove everything except eagles, letters, numbers, and space
                               .strip
                               .unicode_downcase
                content_sim = replace_digit_sequences_with_words(content_sim)
                {
                  content: f,
                  content_sim: content_sim,
                  subtitle_count: 1,
                  index: st_index += 1,
                  repetitions: StringComputations.repetitions(content_sim),
                  para_index: para_index,
                  record_id: para_record_id,
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
          def enrich_st_attrs(st_attrs_list, st_objects)
            if st_attrs_list.length != st_objects.length
              puts st_attrs_list.ai(indent: -2)
              puts st_objects.ai(indent: -2)
              raise(
                MismatchingSubtitleCountsError.new(
                  "Mismatch in counts: st_attrs_list: #{ st_attrs_list.length }, st_objects: #{ st_objects.length }"
                )
              )
            end

            if st_objects.any? { |st| st.persistent_id.nil? }
              raise(
                EncounteredNilStidError.new(
                  "Encountered subtitle with nil persistent_id!"
                )
              )
            end

            r = []
            st_attrs_list.each_with_index { |st_attrs, idx|
              st_obj = st_objects[idx]
              r << st_attrs.merge({
                persistent_id: st_obj.persistent_id,
              })
            }
            r
          end

          # Replaces sequences of digits with their word forms:
          # "21, 22, 23, 24, 25"
          #  =>
          # "twenty one, twenty two, twenty three, twenty four, twenty five"
          # @param a_string [String]
          # @return [String]
          NUMBER_SEQUENCE_REGEX = /
            \d+       # one or more digits
            (?:       # start of non-matching group
              \s+     # one or more space
              \d+     # followed by one or more digits
            ){2,}        # two or more
          /x
          def replace_digit_sequences_with_words(a_string)
            new_string = a_string.dup
            a_string.scan(/(#{ NUMBER_SEQUENCE_REGEX })/) { |m|
              numbers = m[0].split(" ")
              numbers_in_words = numbers.map { |e|
                Utils::NumberToWordConverter.convert(e.to_i)
              }.join(' ')
              new_string.sub!(NUMBER_SEQUENCE_REGEX, numbers_in_words)
            }
            new_string
          end

        end
      end
    end
  end
end
