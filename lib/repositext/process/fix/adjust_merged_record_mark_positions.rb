class Repositext
  class Process
    class Fix
      # Moves :record_marks that are in invalid positions to a position symmetrically
      # between two paragraphs.
      class AdjustMergedRecordMarkPositions

        # @param [String] text
        # @param [String] filename
        # @return [Outcome]
        def self.fix(text, filename)
          # Specify regexes
          ald_any_chars_rx = /\\\}|[^\}]/
          ial_rx = /\{:#{ ald_any_chars_rx }*?\}/
          # TODO: record_mark_rx only matches :record_marks with IALs. Check if there are
          # :record_marks without IALs.
          record_mark_rx = /\n\^\^\^\s#{ ial_rx }\n/
          # prepend \n\n to satisfy two leading \n for :record_mark on first line in file
          old_at = "\n\n" + text
          new_at = ''
          state = 'idle'
          invalid_record_mark = nil
          s = StringScanner.new(old_at)

          while !s.eos? do
            case state
            when 'idle'
              state, new_at = idle_state_handler!(s, new_at, record_mark_rx)
            when 'capture_invalid_record_mark'
              state, invalid_record_mark = capture_invalid_record_mark_state_handler!(s, record_mark_rx)
            when 'move_to_closest_para_break'
              state, new_at = move_to_closest_para_break_state_handler!(s, new_at, invalid_record_mark)
            else
              raise "Invalid state: #{ state.inspect }"
            end

            # move symmetrically between two paras
            new_at.gsub!(/\n\n(#{ record_mark_rx })([^\n])/, "\n\\1\n\\2")
          end

          new_at = new_at.lstrip # remove temporary leading \n\n
          new_at = make_sure_there_is_a_blank_line_after_first_record_mark(new_at)
          new_at = apply_custom_fixes(new_at, filename)
          Outcome.new(true, { contents: new_at }, [])
        end

        # Handles the idle state that tries to find a record_mark in an invalid
        # position. Transitions state to 'capture_invalid_record_mark'.
        # @param [StringScanner] s
        # @param [String] new_at
        # @param [Regex] record_mark_rx
        # @return [Array<String, String>] [new_state, new_at]
        def self.idle_state_handler!(s, new_at, record_mark_rx)
          # Match up until the next invalid record_mark, excluding the record mark itself
          contents = s.scan(/.*?[^\n](?=#{ record_mark_rx })/m)

          state = if contents
            # Found an invalid record_mark
            new_at << contents
            'capture_invalid_record_mark'
          else
            # No invalid record_mark found
            new_at << s.rest
            s.terminate
            'idle'
          end

          [state, new_at]
        end

        # Captures the record_mark in an invalid position. Transitions state to
        # 'move_to_closest_para_break'.
        # @param [StringScanner] s
        # @param [Regex] record_mark_rx
        # @return [Array<String, String>] [new_state, invalid_record_mark]
        def self.capture_invalid_record_mark_state_handler!(s, record_mark_rx)
          invalid_record_mark = s.scan(record_mark_rx)

          state = if invalid_record_mark
            'move_to_closest_para_break'
          else
            raise "No invalid record_mark found: ...#{ new_at[-30..-1].inspect } - #{ s.rest[0..30].inspect }"
          end

          [state, invalid_record_mark]
        end

        # Moves the record_mark from an invalid position to the closest paragraph
        # boundary. Transitions state back to 'idle'.
        # @param [StringScanner] s
        # @param [String] new_at
        # @param [String] invalid_record_mark
        # @return [Array<String, String>] [new_state, new_at]
        def self.move_to_closest_para_break_state_handler!(s, new_at, invalid_record_mark)
          # find preceding para_break
          prev_dist = distance_to_last_para_break(new_at)
          # find following para_break
          foll_dist = distance_to_first_para_break(s.rest)
          # move record_mark to closest para_break

          if(Float::INFINITY == prev_dist && Float::INFINITY == foll_dist)
            # TODO: raise a warning. This should not occur.
            # there is neither previous nor following para_break.
            # just wrap up the doc
            new_at << s.rest
            new_at << invalid_record_mark
            s.terminate
          elsif prev_dist < foll_dist
            # move to previous
            new_at.insert(-prev_dist, invalid_record_mark)
          elsif foll_dist <= prev_dist
            # move to following
            # capture text until next para or end of string
            contents = s.scan(/.*?\n(?=\n)/m)
            new_at << contents ? contents : s.rest
            new_at << invalid_record_mark
          else
            raise "Should never get here! #{ prev_dist.inspect }, #{ foll_dist.inspect }, #{ invalid_record_mark.inspect }"
          end

          state = 'idle'
          [state, new_at]
        end

        # Returns the number of characters from the end of txt to the last
        # para break (\n\n). Returns infinity if no para break is found.
        # @param [String] txt
        def self.distance_to_last_para_break(txt)
          v = txt.rindex("\n\n")
          v.nil? ? Float::INFINITY : (txt.length - 1) - v
        end

        # Returns the number of characters from the beginning of txt to the first
        # para break (\n\n). Returns infinity if no para break is found.
        # @param [String] txt
        def self.distance_to_first_para_break(txt)
          v = txt.index("\n\n")
          v.nil? ? Float::INFINITY : v + 1
        end

        # @param [String] txt
        # @return [String] txt with blank line after first record_mark
        def self.make_sure_there_is_a_blank_line_after_first_record_mark(txt)
          txt.gsub(/\A(\^\^\^[^\n]*)\n+/, '\1' + "\n\n")
        end

        # Override this method for any custom fixes in sub classes
        # @param [String] txt the text to fix
        # @param [String] filename
        # @return [String] the fixed text
        def self.apply_custom_fixes(txt, filename)
          txt
        end

      end
    end
  end
end
