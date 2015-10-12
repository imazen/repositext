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
              ['!)', 'rtxtExclPaCl'], # added for spn
              ['!,', 'rtxtExclComm'], # added for spn
              ['!:', 'rtxtExclColo'], # added for spn
              ['!;', 'rtxtExclSemi'], # added for spn
              ['!—', 'rtxtExclEmda'], # added for spn
              ['!’', 'rtxtExclTsqc'], # added for afr
              ['!”', 'rtxtExclTdqc'],
              ['!…', 'rtxtExclElip'], # added for spn
              ['.!', 'rtxtPeriExcl'], # added for spn
              ['.(', 'rtxtPeriPaOp'], # added for spn
              ['.)', 'rtxtPeriPaCl'], # added for spn
              ['.,', 'rtxtPeriComm'], # added for spn
              ['.-', 'rtxtPeriHyph'], # should the hyphen be replaced with emdash in source? uds.-uds.
              ['.;', 'rtxtPeriSemi'], # added for spn
              ['.?', 'rtxtPeriQues'], # added for spn
              ['.[', 'rtxtPeriBrOp'], # added for spn
              ['.—', 'rtxtPeriEmda'], # added for spn
              ['.’', 'rtxtPeriTsqc'], # added for afr
              ['.”', 'rtxtPeriTdqc'], # added for afr
              ['.…', 'rtxtPeriElip'], # added for spn
              ['?)', 'rtxtQuesPaCl'], # added for spn
              ['?,', 'rtxtQuesComm'], # added for spn
              ['?.', 'rtxtQuesPeri'], # added for spn
              ['?:', 'rtxtQuesColo'], # added for spn
              ['?;', 'rtxtQuesSemi'], # added for spn
              ['?—', 'rtxtQuesEmda'], # added for spn
              ['?’', 'rtxtQuesTsqc'], # added for afr
              ['?”', 'rtxtQuesTdqc'],
              ['?…', 'rtxtQuesElip'], # added for spn
              ['…”', 'rtxtElipTdqc'], # added for spn
              ['—', 'rtxtEmdash'],
              ['?&#x00A0;', 'rtxt_ques_nbsp'], # added for frn
              ['', 'rtxtEagle'],
            ]
          end

        end
      end
    end
  end
end
