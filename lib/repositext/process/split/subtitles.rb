class Repositext
  class Process
    class Split
      # Splits a foreign_file's subtitles based on subtitles in primary_file.
      class Subtitles

        # @param foreign_file [Repositext::RFile::ContentAt]
        # @param primary_file [Repositext::RFile::ContentAt]
        def initialize(foreign_file, primary_file)
          raise ArgumentError.new("Invalid foreign_file: #{ foreign_file.inspect }")  unless foreign_file.is_a?(RFile::ContentAt)
          raise ArgumentError.new("Invalid primary_file: #{ primary_file.inspect }")  unless primary_file.is_a?(RFile::ContentAt)
          @foreign_file = foreign_file
          @primary_file = primary_file
        end

        # @return [Outcome] with foreign content AT as String in result.
        def split
          # Compute structural similarity for original content AT files.
          # All subsequent code operates on plain text versions where we can't
          # compute structural similarity reliably.
          content_at_structural_similarity = compute_content_at_structural_similarity(
            @primary_file.contents,
            @foreign_file.contents
          )

          primary_sequence = compute_primary_sequence(@primary_file.contents, @primary_file.language)
          foreign_sequence = compute_foreign_sequence(@foreign_file.contents, @foreign_file.language)
          bilingual_sequence_pair = BilingualSequencePair.new(
            primary_sequence,
            foreign_sequence,
            { structural_similarity_override: content_at_structural_similarity }
          )
          sanitized_aligned_paragraph_pairs = encode_merged_paragraph_contents(
            sanitize_aligned_paragraph_pairs(
              bilingual_sequence_pair.aligned_paragraph_pairs
            )
          )
          foreign_plain_text_with_subtitles = decode_merged_paragraph_contents(
            copy_subtitles_to_foreign_plain_text(
              sanitized_aligned_paragraph_pairs
            )
          )
          foreign_content_at_with_subtitles = Suspension::TokenReplacer.new(
            foreign_plain_text_with_subtitles,
            @foreign_file.contents
          ).replace(:subtitle_mark)
          foreign_content_at_with_adjusted_subtitles = adjust_subtitles(
            Text.new(foreign_content_at_with_subtitles, @foreign_file.language)
          )
          validate_no_content_changed(
            @foreign_file.contents,
            foreign_content_at_with_adjusted_subtitles
          )
          Outcome.new(true, foreign_content_at_with_adjusted_subtitles)
        end

      private

        # Computes structural similarity for the original content ATs
        # @param primary_contents [String]
        # @param foreign_contents [String]
        # @return [Hash]
        def compute_content_at_structural_similarity(primary_contents, foreign_contents)
          kramdown_options = {
            input: 'KramdownRepositext',
            line_width: 100000, # set to very large value so that each para is on a single line
          }
          Kramdown::TreeStructuralSimilarity.new(
            Kramdown::Document.new(primary_contents, kramdown_options),
            Kramdown::Document.new(foreign_contents, kramdown_options),
          ).compute
        end

        # @param txt [String] the primary contents in KramdownRepositext format.
        # @param language [Language] the primary language
        # @return [Sequence] A sequence object with all tokens except headers
        #    and subtitle_marks removed.
        def compute_primary_sequence(txt, language)
          primary_contents_with_subtitles_only = Suspension::TokenRemover.new(
            txt,
            Suspension::REPOSITEXT_TOKENS.find_all { |e|
              ![:header_atx, :subtitle_mark].include?(e.name)
            }
          ).remove
          primary_contents_with_subtitles_only = encode_document_for_paragraph_splitting(
            primary_contents_with_subtitles_only
          )
          Sequence.new(primary_contents_with_subtitles_only, language)
        end

        # @param txt [String] the foreign contents in KramdownRepositext format.
        # @param language [Language] the foreign language
        # @return [Sequence] a sequence object with all tokens except headers removed.
        def compute_foreign_sequence(txt, language)
          foreign_contents_without_tokens = Suspension::TokenRemover.new(
            txt,
            Suspension::REPOSITEXT_TOKENS.find_all { |e|
              ![:header_atx].include?(e.name)
            }
          ).remove
          foreign_contents_without_tokens = encode_document_for_paragraph_splitting(
            foreign_contents_without_tokens
          )
          Sequence.new(foreign_contents_without_tokens, language)
        end

        # Encodes double newlines inbetween merged paragraphs.
        # @param bpps [Array<BilingualParagraphPair>]
        #     With primary and foreign plain text.
        # @return [Array<BilingualParagraphPair>] with encoded double newlines
        def encode_merged_paragraph_contents(bpps)
          bpps.map { |bpp|
            if [bpp.primary_contents, bpp.foreign_contents].any? { |e| e =~ /\n\n(?!\z)/ }
              # Requires encoding
              BilingualParagraphPair.new(
                Paragraph.new(
                  bpp.primary_contents.gsub(/\n\n(?!\z)/, ' rtxtNewlNewl'),
                  bpp.primary_language
                ),
                Paragraph.new(
                  bpp.foreign_contents.gsub(/\n\n(?!\z)/, ' rtxtNewlNewl'),
                  bpp.foreign_language
                ),
                bpp.confidence
              )
            else
              # No encoding required, use as is
              bpp
            end
          }
        end

        # Decodes double newlines inbetween merged paragraphs.
        # @param txt [String]
        # @return [String] foreign plain text with decoded double newlines
        def decode_merged_paragraph_contents(txt)
          # Note: We have to convert double newlines to single ones in order to
          # behave identical to what happens to trailing double newlines.
          txt.gsub(/ (@?)rtxtNewlNewl/, "\n" + '\1')
        end

        # Prepares aligned_paragraph_pairs for subtitle splitting:
        # Merges pairs with gaps into previous paragraph pair.
        # Note: Does not merge paragraphs into headers! This could result in
        # subtitle_marks being interpolated into headers which is something we
        # don't want. Headers never contain subtitles.
        # @param bpps [Array<BilingualParagraphPair>]
        #     With primary and foreign plain text.
        # @return [Array<BilingualParagraphPair>] with no more gaps
        def sanitize_aligned_paragraph_pairs(bpps)
          # return as is if there are no gapped bpps
          return bpps  if bpps.none? { |e| 0.0 == e.confidence }
          sanitized_bpps = []
          bpps.each { |bpp|
            prev_bpp = sanitized_bpps[-1]
            if(
              prev_bpp && # previous bpp exists
              [:primary_contents, :foreign_contents].none? { |e| prev_bpp.send(e) =~ /\A#/ } && # previous bpp is not a header
              (
                0.0 == bpp.confidence || # current bpp has gap
                [:primary_contents, :foreign_contents].any? { |e| '' == prev_bpp.send(e) } # previous bpp has gap
              )
            )
              # merge
              sanitized_bpps[-1] = BilingualParagraphPair.merge([prev_bpp, bpp])
            else
              # Use as is
              sanitized_bpps << bpp
            end
          }
          sanitized_bpps
        end

        # Returns foreign plain text with subtitles inserted.
        # @param bilingual_paragraph_pairs [Array<BilingualParagraphPair>]
        #     With primary and foreign plain text.
        # @return [String] foreign plain text with subtitles.
        def copy_subtitles_to_foreign_plain_text(bilingual_paragraph_pairs)
          r = bilingual_paragraph_pairs.map { |bilingual_paragraph_pair|
            bilingual_paragraph_pair.aligned_text_pairs.map { |btp|
              insert_subtitles_into_foreign_text(btp.primary_contents, btp.foreign_contents)
            }
          }.map { |sentences|
            sentences.join(' ')
          }.join("\n")
          decode_document_after_paragraph_splitting(r)
        end

        # Encodes a document for paragraph splitting.
        # @param txt [String]
        # @return [String]
        def encode_document_for_paragraph_splitting(txt)
          txt.gsub(/^#([^\n]+)\n\n/, '#\1' + "\n")
        end

        # Decodes a document after paragraph splitting.
        # @param txt [String]
        # @return [String]
        def decode_document_after_paragraph_splitting(txt)
          txt.gsub(/^#([^\n]+)\n/, '#\1' + "\n\n")
        end

        # Inserts subtitles from primary_text into foreign_text
        # @param primary_text [String] as plain text with subtitles
        # @param foreign_text [String] as plain text without subtitles
        # @return [String] the foreign plain text with subtitles inserted.
        def insert_subtitles_into_foreign_text(primary_text, foreign_text)
          subtitle_count = primary_text.count('@')
          if 0 == subtitle_count
            # Return as is
            foreign_text
          elsif 1 == subtitle_count
            # Prepend one subtitle
            '@' << foreign_text
          else
            # Interpolate multiple subtitles
            interpolate_multiple_subtitles(primary_text, foreign_text)
          end
        end

        # @param foreign_text [Text] The foreign content AT with subtitles placed.
        # @return [String] the foreign content AT with adjusted subtitles.
        def adjust_subtitles(foreign_text)
          Fix::MoveSubtitleMarksToNearbySentenceBoundaries.new(foreign_text).fix.result
        end

        # Inserts multiple subtitles based on word interpolation.
        # @param primary_text [String] a sentence or paragraph of plain text
        # @param foreign_text [String] a sentence or paragraph of plain text
        # @return [String] foreign plain text with subtitles inserted.
        def interpolate_multiple_subtitles(primary_text, foreign_text)
          primary_words = primary_text.split(' ')
          primary_subtitle_indexes = primary_words.each_with_index.inject([]) { |m, (word, idx)|
            m << idx  if word.index('@')
            m
          }
          foreign_words = foreign_text.split(' ')
          foreign_words = ['']  if foreign_words.empty?
          word_scale_factor = foreign_words.length / primary_words.length.to_f
          foreign_subtitle_indexes = primary_subtitle_indexes.map { |e|
            (e * word_scale_factor).floor
          }
          foreign_subtitle_indexes.each { |i| foreign_words[i].prepend('@') }
          foreign_words.join(' ')
        end

        # @param original_foreign_contents [String]
        # @param split_foreign_contents [String]
        def validate_no_content_changed(original_foreign_contents, split_foreign_contents)
          if original_foreign_contents.gsub('@', '') != split_foreign_contents.gsub('@', '')
            raise "They are different!"
          end
        end

      end
    end
  end
end
