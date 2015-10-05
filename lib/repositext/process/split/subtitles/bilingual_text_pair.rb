class Repositext
  class Process
    class Split
      class Subtitles

        # Represents a pair of corresponding text in primary and foreign language.
        class BilingualTextPair

          attr_reader :foreign_text, :primary_text

          # Merges contents of bilingual_text_pairs into a single bilingual_text_pair.
          # @param btps [Array<BilingualTextPair>]
          # @return [BilingualTextPair]
          def self.merge(btps)
            primary_language = btps.first.primary_language
            foreign_language = btps.first.foreign_language
            if !btps.all? { |btp| btp.primary_language == primary_language }
              raise ArgumentError.new("Invalid primary language: #{ btps.inspect }")
            end
            if !btps.all? { |btp| btp.foreign_language == foreign_language }
              raise ArgumentError.new("Invalid foreign language: #{ btps.inspect }")
            end
            merged_contents = btps.inject([[], []]) { |m, btp|
              # Merge each language's sentences together
              primary_txt = btp.primary_contents
              foreign_txt = btp.foreign_contents
              m.first << primary_txt  if '' != primary_txt.to_s # skip blank segments
              m.last << foreign_txt  if '' != foreign_txt.to_s # skip blank segments
              m
            }
            BilingualTextPair.new(
              Text.new(merged_contents.first.join(' '), primary_language),
              Text.new(merged_contents.last.join(' '), foreign_language)
            )
          end

          def initialize(primary_text, foreign_text)
            raise ArgumentError.new("Invalid primary_text: #{ primary_text.inspect }")  unless primary_text.is_a?(Text)
            raise ArgumentError.new("Invalid foreign_text: #{ foreign_text.inspect }")  unless foreign_text.is_a?(Text)
            @primary_text = primary_text
            @foreign_text = foreign_text
          end

          def confidence
            if 0.0 == min_word_length
              # One of the contents is a gap, no confidence in alignment
              0.0
            else
              # Check length_ratio
              if length_ratio_in_words_is_within_bounds
                1.0
              else
                [length_ratio_in_words, 1/length_ratio_in_words.to_f].min
              end
            end
          end

          def confidence_boundaries
            # We use max_word_length to get the boundaries as they get stricter
            # the longer a sentence is.
            # This will detect places where a long sentence is pair up with a
            # very short one.
            case max_word_length
            when 0
              raise "Should never get here"
            when 1
              [0.4, 2.0]
            when 2
              [0.45, 1.9]
            when 3
              [0.48, 1.85]
            when 4
              [0.52, 1.8]
            when 5
              [0.55, 1.75]
            when 6
              [0.58, 1.7]
            when 7
              [0.62, 1.65]
            when 8
              [0.63, 1.6]
            when 9
              [0.68, 1.58]
            when 10..14
              [0.7, 1.52]
            when 15..19
              [0.75, 1.4]
            when 20..29
              [0.8, 1.3]
            when 30..39
              [0.85, 1.2]
            when 40..49
              [0.9, 1.12]
            when 50..59
              [0.95, 1.1]
            else
              [0.97, 1.08]
            end
          end

          def foreign_contents
            foreign_text.contents
          end

          def foreign_language
            foreign_text.language
          end

          def inspect
            %(#<#{ self.class.name }:#{ object_id } @primary_text=#{ @primary_text.inspect } @foreign_text=#{ @foreign_text.inspect } @confidence=#{ confidence }>)
          end

          # def length_ratio_in_chars
          #   @length_ratio_in_chars ||= (
          #     if 0 == min_char_length
          #       0.0
          #     else
          #       foreign_text.length_in_chars / primary_text.length_in_chars.to_f
          #     end
          #   )
          # end

          def length_ratio_in_words
            if 0 == min_word_length
              0.0
            else
              foreign_text.length_in_words / primary_text.length_in_words.to_f
            end
          end

          def length_ratio_in_words_is_within_bounds
            lower_bound, upper_bound = confidence_boundaries
            length_ratio_in_words >= lower_bound && length_ratio_in_words <= upper_bound
          end

          # def max_char_length
          #   @max_char_length ||= [
          #     primary_text.length_in_chars,
          #     foreign_text.length_in_chars(adjusted: true),
          #   ].max
          # end

          def max_word_length
            [
              primary_text.length_in_words,
              foreign_text.length_in_words,
            ].max
          end

          # def min_char_length
          #   @min_char_length ||= [
          #     primary_text.length_in_chars,
          #     foreign_text.length_in_chars(adjusted: true),
          #   ].min
          # end

          def min_word_length
            [
              primary_text.length_in_words,
              foreign_text.length_in_words,
            ].min
          end

          def primary_contents
            primary_text.contents
          end

          def primary_language
            primary_text.language
          end

          def to_s
            inspect
          end

        end

      end
    end
  end
end
