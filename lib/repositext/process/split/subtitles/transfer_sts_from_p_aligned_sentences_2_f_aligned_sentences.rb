class Repositext
  class Process
    class Split
      class Subtitles

        # This name space provides methods for transferring subtitles from
        # primary to foreign aligned sentences.
        module TransferStsFromPAlignedSentences2FAlignedSentences

          # @param asp [Array<Array<String, Nil>>] the aligned sentence pairs.
          #   [["p sentence 1", "f sentence 1"], ["p sentence 1", nil], ...]
          # @return [Outcome] with asp with aligned subtitle pairs as result.
          def transfer_sts_from_p_aligned_sentences_2_f_aligned_sentences(asp)
            asp_w_f_sts = asp.map { |(p_s, f_s)|
              # Return as is if either of the sentences is nil.
              next [p_w, f_s]  if p_s.nil? || f_s.nil?

              # Otherwise transfer subtitles to foreign sentence
              f_s_w_st_o = transfer_subtitles_to_foreign_sentence(p_s, f_s)
              [p_s, f_s_w_st_o.result]
            }
            f_s_w_sts = asp_w_f_sts.map(&:last)

            Outcome.new(true, f_s_w_sts)
          end

          # Transfers subtitles from primary sentence to foreign sentence.
          # @param p_s [String] primary sentence with subtitles
          # @param f_S [String] foreign sentence without subtitles
          # @return [Outcome] with the foreign sentence with subtitles inserted as result.
          def transfer_subtitles_to_foreign_sentence(p_s, f_s)
            subtitle_count = p_s.count('@')
            if 0 == subtitle_count
              # Return as is
              Outcome.new(true, f_s)
            elsif((1 == subtitle_count) && (p_s =~ /\A@/))
              # Prepend one subtitle
              Outcome.new(true, '@' << f_s)
            else
              transfer_complex_subtitles(p_s, f_s)
            end
# TODO: return an outcome from this method!
          end

          # @param p_s [String] primary sentence with subtitles
          # @param f_S [String] foreign sentence without subtitles
          # @return [Outcome] with the foreign sentence with subtitles inserted as result.
          def transfer_complex_subtitles(p_s, f_s)
            # Interpolate multiple subtitles
            interpolate_multiple_subtitles(p_s, f_s)
          end

          # Inserts multiple subtitles based on word interpolation.
          # @param p_s [String] primary sentence with subtitles
          # @param f_S [String] foreign sentence without subtitles
          # @return [Outcome] with the foreign sentence with subtitles inserted as result.
          def interpolate_multiple_subtitles(p_s, f_s)
            primary_words = p_s.split(' ')
            primary_subtitle_indexes = primary_words.each_with_index.inject([]) { |m, (word, idx)|
              m << idx  if word.index('@')
              m
            }
            foreign_words = f_s.split(' ')
            foreign_words = ['']  if foreign_words.empty?
            word_scale_factor = foreign_words.length / primary_words.length.to_f
            foreign_subtitle_indexes = primary_subtitle_indexes.map { |e|
              (e * word_scale_factor).floor
            }
            foreign_subtitle_indexes.each { |i| foreign_words[i].prepend('@') }

            Outcome.new(true, foreign_words.join(' '))
          end

        end
      end
    end
  end
end
