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
                  repetitions: detect_string_repetitions(content_sim),
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

          # Detects if a_string contains any repeated sequences with minimum
          # length of ngram_length.
          # Example:
          #     "here we go repetition number one, repetition number two, repetition number three. And then some more"
          # will return this:
          #     { " repetition number " => [10, 33, 56] }
          # @param a_string [String]
          # @return [Hash] with repeated strings as keys and start positions as vals.
          def detect_string_repetitions(a_string)
            ngram_length = 8 # needs to by synched with sim_right!
            string_length = a_string.length
            return {}  if string_length <= ngram_length

            start_pos = 0
            ngrams = {}
            while(start_pos + ngram_length) <= string_length do
              test_string = a_string[start_pos, ngram_length]
              ngrams[test_string]  ||= []
              ngrams[test_string] << start_pos
              start_pos += 1
            end

            max_rep_count = ngrams.inject(0) { |m,(k,v)| [m, v.length].max }
            return {}  if max_rep_count <= 1

            reps = ngrams.inject({}) { |m,(k,v)|
              m[k] = v  if v.length == max_rep_count
              m
            }
            # reps looks like this:
            # {
            #   " repetitio"=>[10, 33, 56],
            #   "repetition"=>[11, 34, 57],
            #   "epetition "=>[12, 35, 58],
            #   "petition n"=>[13, 36, 59],
            #   "etition nu"=>[14, 37, 60],
            #   "tition num"=>[15, 38, 61],
            #   "ition numb"=>[16, 39, 62],
            #   "tion numbe"=>[17, 40, 63],
            #   "ion number"=>[18, 41, 64],
            #   "on number "=>[19, 42, 65]
            # }

            current_start_pos = -1
            prev_key = ''
            expanded_reps = reps.inject({}) { |m,(k,v)|
              if current_start_pos.succ == v.first
                # is connected, combine the two
                new_key = prev_key + k.last
                m[new_key] = m.delete(prev_key) || v
                prev_key = new_key
              else
                # Not connected, start new capture group
                m[k] = v
                prev_key = k
              end
              current_start_pos = v.first
              m
            }

            expanded_reps
          end
        end
      end
    end
  end
end
