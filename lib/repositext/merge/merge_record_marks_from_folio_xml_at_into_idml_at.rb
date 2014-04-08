class Repositext
  class Merge
    class RecordMarksFromFolioXmlAtIntoIdmlAt

      # @param[String] at_folio
      # @param[String] at_idml
      # @return[String] at with merged tokens
      def self.merge(at_folio, at_idml)
        case 'use_4'
        when 'use_1'
          # Get plain text from at_idml
          at_without_tokens = Suspension::TokenRemover.new(
            at_idml,
            Suspension::REPOSITEXT_TOKENS
          ).remove

          # Add :record_mark tokens only to at_idml plain text
          at_with_record_marks_only = Suspension::TextReplayer.new(
            at_without_tokens,
            at_folio,
            Suspension::REPOSITEXT_TOKENS.find_all { |e| [:record_mark].include?(e.name) }
          ).replay

          # Remove :record_mark tokens from at_idml
          at_without_record_marks = Suspension::TokenRemover.new(
            at_idml,
            Suspension::REPOSITEXT_TOKENS.find_all { |e| [:record_mark].include?(e.name) }
          ).remove

          # Add :record_marks to text and all other tokens.
          at_with_merged_tokens = Suspension::TokenReplacer.new(
            at_with_record_marks_only,
            at_without_record_marks
          ).replace([:record_mark])
        when 'use_2'
          # Get txt from at_idml
          at_idml_txt_only = Suspension::TokenRemover.new(
            at_idml,
            Suspension::REPOSITEXT_TOKENS
          ).remove

          # Remove all tokens but :record_mark from at_folio
          # Need to retain both :record_mark as well as the connected :ial_span.
          # Otherwise only '^^^' would be left (without the IAL)
          at_folio_with_record_marks_only = Suspension::TokenRemover.new(
            at_folio,
            Suspension::REPOSITEXT_TOKENS.find_all { |e| ![:ial_span, :record_mark].include?(e.name) }
          ).remove

          # Replay idml text changes on at_folio_with_record_marks_only
          at_with_record_marks_only = Suspension::TextReplayer.new(
            at_idml_txt_only,
            at_folio_with_record_marks_only,
            Suspension::REPOSITEXT_TOKENS
          ).replay

          # Remove :record_mark tokens from at_idml (there shouldn't be any in there, just to be sure)
          at_idml_without_record_marks = Suspension::TokenRemover.new(
            at_idml,
            Suspension::REPOSITEXT_TOKENS.find_all { |e| :record_mark == e.name }
          ).remove

          # Add :record_marks to text and all other tokens.
          at_with_merged_tokens = Suspension::TokenReplacer.new(
            at_with_record_marks_only,
            at_idml_without_record_marks
          ).replace([:record_mark])
        when 'use_3'
          # Get txt only from both
          at_idml_txt_only = Suspension::TokenRemover.new(
            at_idml,
            Suspension::REPOSITEXT_TOKENS
          ).remove
          at_folio_txt_only = Suspension::TokenRemover.new(
            at_folio,
            Suspension::REPOSITEXT_TOKENS
          ).remove
          # Split into paras
          splitter = Proc.new { |doc|
            doc.downcase
               .gsub(/[^[:alnum:] \n]/, '')
               .split("\n")
               .find_all{ |e| '' != e.to_s.strip }
               .map { |e| e[0..40] }
          }
          at_idml_para_markers = splitter.call(at_idml_txt_only)
          at_folio_para_markers = splitter.call(at_folio_txt_only)
          # Generate docs with para beginnings only
          at_idml_para_doc = at_idml_para_markers.join("\n")
          at_folio_para_doc = at_folio_para_markers.join("\n")
          # Diff them
          diff = Suspension::DiffAlgorithm.new.call(
            at_idml_para_doc, at_folio_para_doc
          )

          longest_length = [at_idml_para_markers.length, at_folio_para_markers.length].max
          combined = longest_length.times.map do |idx|
            "#{ at_idml_para_markers[idx] } <---> #{ at_folio_para_markers[idx] }"
          end
        when 'use_4'
          # split folio on record marks
          # align IDML with folio based on plain text only for both
          # NOTE: It's important to consume the leading \n and add it back
          # a few lines down to make sure that :record_marks are always at the
          # beginning of a line. Otherwise they won't be matched by Suspension regex.
          folio_records = at_folio.split(/\n(?=\^\^\^)/)
                                  .each_with_index
                                  .map do |folio_record, record_idx|
            txt_only = Suspension::TokenRemover.new(
              folio_record,
              Suspension::REPOSITEXT_TOKENS
            ).remove
            simplified_line_starts = txt_only.split(/\n/)
                                             .map { |e| simplify_line(e) }
                                             .find_all { |e| '' != e }
            # add the leading \n back in to all but first record (removed above during split)
            {
              :folio => {
                :original_at => (0 == record_idx ? '' : "\n") + folio_record,
                :txt_only => txt_only,
                :simplified_line_starts => simplified_line_starts
              },
              :idml => {
                :original_at => '',
                :txt_only => '',
                :simplified_line_starts => []
              }
            }
          end
          # split idml on paragraphs
          idml_paras = at_idml.split(/(?<=\n\n)/).map { |idml_para|
            txt_only = Suspension::TokenRemover.new(
              idml_para,
              Suspension::REPOSITEXT_TOKENS
            ).remove
            raise("Para contained line break: #{ txt_only.inspect }")  if txt_only.strip =~ /\n/
            {
              :original_at => idml_para,
              :txt_only => txt_only,
              :simplified_line_start => simplify_line(txt_only)
            }
          }
          # align idml_paras with folio_records
          folio_records.each do |folio_record|
puts '--- NEW FOLIO RECORD -------------------------------------'
            # init loop vars
            folio_simplified_line_starts = folio_record[:folio][:simplified_line_starts].dup
            found_any_matching_idml_paras = false
            keep_looking = true
            idml_lines_to_fetch = 0
            # align all matching idml_paras with record
            while(keep_looking) do
              # init loop vars
              idml_lines_to_fetch += 1
              matching_folio_line_start = nil
              if(
                next_idml_para = idml_paras[idml_lines_to_fetch-1] and
                simplified_idml_line = next_idml_para[:simplified_line_start] and
                (
                  '' == simplified_idml_line ||
                  (matching_folio_line_start = folio_simplified_line_starts.detect { |simplified_folio_line|
                    similarity_detector(simplified_idml_line, simplified_folio_line)
                  })
                )
              )
                # Remove the matching folio_record line from the pool
                match_index = folio_simplified_line_starts.index(matching_folio_line_start)
                folio_simplified_line_starts.delete_at(match_index)#  if match_index
                # add idml_paras
                idml_lines_to_fetch.times do
                  idml_para = idml_paras.shift
                  folio_record[:idml][:original_at] << idml_para[:original_at]
                  folio_record[:idml][:txt_only] << idml_para[:txt_only]
                  folio_record[:idml][:simplified_line_starts] << idml_para[:simplified_line_start]
                end
                idml_lines_to_fetch = 0 # reset after a match
                found_any_matching_idml_paras = true
              elsif idml_lines_to_fetch > 2
                keep_looking = false
              end
            end
            if !found_any_matching_idml_paras
              raise "Could not find any matching IDML paras for folio #{ folio_record.inspect }"
            else
ap({ :folio => folio_record[:folio][:txt_only], :idml => folio_record[:idml][:txt_only] })
            end
          end

          at_with_merged_tokens = ''

          folio_records.each do |aorb|
            # Get txt from at_idml
            at_idml_txt_only = Suspension::TokenRemover.new(
              aorb[:idml][:original_at],
              Suspension::REPOSITEXT_TOKENS
            ).remove

            # Remove all tokens but :record_mark from at_folio
            # Need to retain both :record_mark as well as the connected :ial_span.
            # Otherwise only '^^^' would be left (without the IAL)
            at_folio_with_record_marks_only = Suspension::TokenRemover.new(
              aorb[:folio][:original_at],
              # TODO: shouldn't the record_mark regex match the related ial_span?
              # allowing ial_span pollutes the text.
              Suspension::REPOSITEXT_TOKENS.find_all { |e| ![:ial_span, :record_mark].include?(e.name) }
            ).remove
            # Replay idml text changes on at_folio_with_record_marks_only
            at_with_record_marks_only = Suspension::TextReplayer.new(
              at_idml_txt_only,
              at_folio_with_record_marks_only,
              Suspension::REPOSITEXT_TOKENS
            ).replay
            # Remove :record_mark tokens from at_idml (there shouldn't be any in there, just to be sure)
            at_idml_without_record_marks = Suspension::TokenRemover.new(
              aorb[:idml][:original_at],
              Suspension::REPOSITEXT_TOKENS.find_all { |e| :record_mark == e.name }
            ).remove

            # Add :record_marks to text and all other tokens.
            record_local_at_with_merged_tokens = Suspension::TokenReplacer.new(
              at_with_record_marks_only,
              at_idml_without_record_marks
            ).replace([:record_mark])

            at_with_merged_tokens << record_local_at_with_merged_tokens
          end


        else
          raise "Invalid use!"
        end
        at_with_merged_tokens
      end

      # Simplifies a line so that it can be compared between folio and idml
      # @param[String] txt
      def self.simplify_line(txt)
        txt.downcase
           .gsub(/[^[:alnum:] \n]+/, ' ')
           .gsub(/\s+/, ' ')
           .strip[0..80]
      end

      # Returns true if str1 and str2 are considered similar enough.
      def self.similarity_detector(str1, str2)
        ss = compute_string_similarity(str1, str2)
        r = ss > 0.2
        r
      end

      # Computes similarity between s1 and s2
      # @param[String] s1
      # @param[String] s2
      # @return[Float] 1.0 = identical, 0.0 = no similarity at all
      def self.compute_string_similarity(s1, s2)
        sim = case
        when s1 == s2
          1.0
        else
          # I tried tokenizing by chars, bigrams and words.
          # Words with at least 2 chars yielded best results.
          s1_words = s1.split.find_all { |e| e.length > 1 }
          s2_words = s2.split.find_all { |e| e.length > 1 }
          sorted_num_of_tokens = [s1_words.length, s2_words.length].sort
          shorter, longer = sorted_num_of_tokens
          if (shorter / longer.to_f) < 0.6
            0
          else
            (s1_words & s2_words).length / (s1_words | s2_words).length.to_f
          end
        end
      end

    end
  end
end
