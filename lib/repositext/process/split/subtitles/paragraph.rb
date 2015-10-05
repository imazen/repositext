class Repositext
  class Process
    class Split
      class Subtitles

        # Represents a paragraph.
        class Paragraph

          attr_accessor :contents, :language

          # @param sequence [Sequence]
          # @param contents [String]
          def initialize(contents, language)
            raise ArgumentError.new("Invalid contents: #{ contents.inspect }")  unless contents.is_a?(String)
            raise ArgumentError.new("Invalid language: #{ language.inspect }")  unless language.is_a?(Language)
            @contents = contents
            @language = language
          end

          def sentences
            @sentences ||= split_into_sentences(@contents, @language)
          end

        private

          # Splits paragraph into sentences.
          # @param contents [String]
          # @param lang [String]
          # @return [Array<String>] Array with one string per sentence.
          def split_into_sentences(contents, language)
            encoded_contents = encode_contents_for_sentence_splitting(contents, language)
            ps = PragmaticSegmenter::Segmenter.new(
              text: encoded_contents,
              language: language.code_2_chars.to_s,
              clean: false
            )
            ps.segment.map { |e|
              Sentence.new(
                decode_contents_after_sentence_splitting(e, language),
                language
              )
            }
          end

          # Encodes a paragraph for sentence splitting
          # @param txt [String]
          # @return [String]
          def encode_contents_for_sentence_splitting(txt, language)
            s = txt.dup
            encoding_rules.each { |from, to| s.gsub!(from, to) }
            s
          end

          # Decodes a paragraph after sentence splitting
          # @param txt [String]
          # @return [String]
          def decode_contents_after_sentence_splitting(txt, language)
            s = txt.dup
            encoding_rules.reverse.each { |from, to| s.gsub!(to, from) }
            s
          end

          # TODO: handle encoding in language
          def encoding_rules
            [
              # ['…?…', '…rtxt_helen…'],
              ['…”', 'rtxt_elip_tdqc'], # added for spn
              ['!,', 'rtxt_excl_comm'], # added for spn
              ['!:', 'rtxt_excl_colo'], # added for spn
              ['!;', 'rtxt_excl_semi'], # added for spn
              ['!—', 'rtxt_excl_emda'], # added for spn
              ['!’', 'rtxt_excl_tsqc'], # added for afr
              ['!”', 'rtxt_excl_tdqc'],
              ['!…', 'rtxt_excl_elip'], # added for spn
              ['.!', 'rtxt_peri_excl'], # added for spn
              ['.,', 'rtxt_peri_comm'], # added for spn
              ['.-', 'rtxt_peri_hyph'], # should the hyphen be replaced with emdash in source? uds.-uds.
              ['.;', 'rtxt_peri_semi'], # added for spn
              ['.?', 'rtxt_peri_ques'], # added for spn
              ['.[', 'rtxt_peri_brop'], # added for spn
              ['.—', 'rtxt_peri_emda'], # added for spn
              ['.’', 'rtxt_peri_tsqc'], # added for afr
              ['.”', 'rtxt_peri_tdqc'], # added for afr
              ['.…', 'rtxt_peri_elip'], # added for spn
              ['?)', 'rtxt_ques_pacl'], # added for spn
              ['?,', 'rtxt_ques_comm'], # added for spn
              ['?:', 'rtxt_ques_colo'], # added for spn
              ['?;', 'rtxt_ques_semi'], # added for spn
              ['?’', 'rtxt_ques_tsqc'], # added for afr
              ['?”', 'rtxt_ques_tdqc'],
              ['?…', 'rtxt_ques_elip'], # added for spn
              ['—', 'rtxt_emdash'],
              ['', 'rtxt_eagle'],
              ['?&#x00A0;', 'rtxt_ques_nbsp'], # added for frn
            ]
          end

        end
      end
    end
  end
end
