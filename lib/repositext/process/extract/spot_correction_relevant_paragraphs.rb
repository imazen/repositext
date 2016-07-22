class Repositext
  class Process
    class Extract

      # Extracts relevant paragraphs from content_at, based on corr's paragraph_number
      class SpotCorrectionRelevantParagraphs

        # @param correction [Hash] correction attrs for a single correction
        # @param txt [String] the complete content AT text to extract relevant paragraphs from
        # @return [Hash] with keys :relevant_paragraphs and :paragraph_start_line_number
        def self.extract(correction, txt)
          # Extract relevant paragraph
          or_match_on_eagle_or_end_of_string = if compute_first_para_num(txt) == correction[:paragraph_number].to_s
            # Don't stop at eagle when looking for paragraph 1, because it would stop at the starting eagle
            ''
          elsif compute_last_para_num(txt) == correction[:paragraph_number].to_s
            # We're looking at the last paragraph, stop at eagle first, or end of string if no eagle present
            '||\z'
          else
            # Stop also at eagle in case we're looking at the last paragraph that doesn't have a subsequent one
            '|'
          end
          # Capture more than a single paragraph for corrections that span paragraph boundaries
          how_many_paras_to_match = ((correction[:becomes] || correction[:submitted]).scan('*{: .pn}').size) + 1
          stop_para_number = how_many_paras_to_match.times.each.inject(
            correction[:paragraph_number]
          ) { |m,e| m.succ }
          relevant_paragraphs = txt.match(
            /
              #{ dynamic_paragraph_number_regex(correction[:paragraph_number], txt) } # match paragraph number span
              .*? # match anything nongreedily
              (
                (?=#{ dynamic_paragraph_number_regex(stop_para_number, txt) }) # stop before next paragraph number
                #{ or_match_on_eagle_or_end_of_string } # or stop after alternatives
              )
            /xm # multiline
          ).to_s
          if '' == relevant_paragraphs
            raise "Could not find paragraph #{ correction[:paragraph_number] }"
          end

          {
            relevant_paragraphs: relevant_paragraphs,
            paragraph_start_line_number: compute_line_number_from_paragraph_number(
              correction[:paragraph_number], txt
            )
          }
        end

        # Returns the number of the last paragraph.
        # @param [String] txt
        # @return [String] the last paragraph number as string
        def self.compute_last_para_num(txt)
          # scan returns an array of arrays. We want the first entry of the last array
          txt.scan(PARA_NUM_REGEX).last.first
        end

        PARA_NUM_REGEX = /^[@%]{0,2}\*(\d+[a-z]?)\*\{\: \.pn\}/

        # Returns the number of the first paragraph. Normally '1', however there
        # are exceptions.
        # @param [String] txt
        # @return [String] the first paragraph number as string
        def self.compute_first_para_num(txt)
          fpn = (txt.match(PARA_NUM_REGEX)[1].to_s.to_i - 1).to_s
          fpn = '1'  if '0' == fpn # in case first para has a number
          fpn
        end

        # Dynamically generates a regex that matches pararaph_number
        # @param [Integer, String] paragraph_number
        # @param [String] txt the containing text, used to determine the first paragraph number (may not be 1)
        def self.dynamic_paragraph_number_regex(paragraph_number, txt)
          if compute_first_para_num(txt) == paragraph_number.to_s
            # First paragraph doesn't have a number, match beginning of document
            /\A/
          else
            /\n[@%]{0,2}\*#{ paragraph_number.to_s.strip }\*\{\:\s\.pn\}/
          end
        end

        # Given txt and paragraph_number, returns the line at which paragraph_number starts
        # @param [Integer, String] paragraph_number
        # @param [String] txt
        # @return [Integer] the line number (1-based)
        def self.compute_line_number_from_paragraph_number(paragraph_number, txt)
          regex = /
            .*? # match anything non greedily
            #{ dynamic_paragraph_number_regex(paragraph_number, txt) } # match paragraph number span
          /xm # multiline
          text_before_paragraph = txt.match(regex).to_s
          line_number = text_before_paragraph.count("\n") + 1
        end

      end
    end
  end
end
