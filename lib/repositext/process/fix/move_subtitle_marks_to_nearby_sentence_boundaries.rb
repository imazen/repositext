class Repositext
  class Process
    class Fix
      class MoveSubtitleMarksToNearbySentenceBoundaries

        # Moves :subtitle_marks to nearby sentence boundaries.

        attr_reader :contents, :language

        delegate :sentence_boundary_position, to: :language

        # @param text [Text] content AT with associated language
        def initialize(text)
          @contents = text.contents
          @language = text.language
        end

        # @return [Outcome] with adjusted contents as result [String]
        def fix
          new_contents = ''
          state = :idle
          ss = StringScanner.new(@contents)

          while !ss.eos? do
            case state
            when :idle
              state = idle_state_handler!(ss, new_contents)
            when :move_subtitle_mark_to_closest_sentence_boundary
              state = move_after_closest_sentence_boundary_state_handler!(ss, new_contents)
            else
              raise "Invalid state: #{ state.inspect }"
            end
          end

          Outcome.new(true, new_contents)
        end

      private

        # Handles the idle state that tries to find the next subtitle_mark.
        # Changes new_contents in place
        # Transitions state to :move_to_closest_sentence_boundary
        # @param ss [StringScanner]
        # @param new_contents [String]
        # @return[Symbol] new_state
        def idle_state_handler!(ss, new_contents)
          # Match up until the the next subtitle_mark_and_surroundings, excluding the match itself
          if(contents = ss.scan_until(/(?=#{ subtitle_mark_and_surroundings_regex })/))
            # Found a subtitle_mark
            new_contents << contents
            :move_subtitle_mark_to_closest_sentence_boundary
          else
            # No subtitle_mark found
            new_contents << ss.rest
            ss.terminate
            :idle
          end
        end

        # Moves the subtitle_mark from its current position to the closest sentence
        # boundary. Transitions state back to :idle.
        # @param ss [StringScanner]
        # @param new_contents [String]
        # @return[Symbol] new_state
        def move_after_closest_sentence_boundary_state_handler!(ss, new_contents)
          smas = extract_subtitle_mark_and_surroundings!(ss)
          iocsb = compute_index_of_closest_sentence_boundary(smas)
          # ['word-3', 'word-2', 'word-1', '@word-0', 'word+1', 'word+2']
          #     0          1         2          3         4         5
          if [2, nil].include?(iocsb)
            # No boundaries nearby, or subtitle_mark is already immediately after boundary,
            # leave smas as is.
          elsif [0, 1].include?(iocsb)
            # Move subtitle_mark forward. Presence of all affected words is implied,
            # so we can move the subtitle_mark without checking.
            smas[iocsb+1].prepend('@')
            smas[3].sub!('@', '')
          elsif [3, 4].include?(iocsb)
            if !smas[iocsb+1].nil?
              # Move subtitle_mark back if there is a word at the subsequent position.
              smas[iocsb+1].prepend('@')
              smas[3].sub!('@', '')
            end
          else
            raise "Should never get here! #{ iocsb.inspect }, #{ smas.inspect }"
          end

          new_contents << smas.compact.join(' ')

          :idle
        end

        # We don't need the \A anchor since we use it with StringScanner#scan
        # which implies \A.
        # @return [Regexp]
        def subtitle_mark_and_surroundings_regex
          /
            (?:                       # optional non capturing group for any minus words
              (?:                       # optional non capturing group for -3 and -2
                (?:(?<word-3>\S+)\ )?     # optional capture group for -3
                (?:(?<word-2>\S+)\ )      # required capture group for -2
              )?
              (?:  (?<word-1>\S+)\ )    # required capture group for -1
            )?
            (?<!^)                    # subtitle mark is not at beginning of line
            (?<word-0>@\S+)           # required word 0 with subtitle-mark
            (?:                       # optional non capturing group for any plus words
              (?:\ (?<word+1>\S+))      # required word plus 1
              (?:\ (?<word+2>\S+))?     # optional word plus 2
            )?
          /x
        end

        # @param ss [StringScanner] positioned 3 words before subtitle_mark
        # @return [Array<String, Nil>] an array with an entry for each surrounding position.
        def extract_subtitle_mark_and_surroundings!(ss)
          r = ss.scan(subtitle_mark_and_surroundings_regex)
          # TODO: We should raise if r is no match! return []  if r.nil?
          %i[word-3 word-2 word-1 word-0 word+1 word+2].map { |e| ss[e] }
        end

        # @param surrounding_words [Array<String>]
        # @return [Integer, Nil] one of -2, -1, 0, 1, 2 or nil if no sentence boundary found
        def compute_index_of_closest_sentence_boundary(surrounding_words)
          # Test surrounding words in order of distance from subtitle_mark.
          # ['word-3', 'word-2', 'word-1', '@word-0', 'word+1', 'word+2']
          #     0          1         2          3         4         5
          # The order below iterates over groups of equidistant words, preferring
          # previous over following.
          [2, 1, 3, 0, 4].detect { |idx| sentence_boundary_position(surrounding_words[idx].to_s) }
        end

      end
    end
  end
end
