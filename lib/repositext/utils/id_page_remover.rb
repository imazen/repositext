class Repositext
  class Utils
    # Removes id page from an AT document
    class IdPageRemover

      # Removes id page and its contents from txt
      # @param txt [String] complete AT document
      # @return [Array<String>] An array of content AT without id page, and the id page
      def self.remove(txt)
        if(ial_pos = txt.index(".id_title1"))
          # txt contains id page, remove it
          # Find beginning of previous line
          # Go back a few chars to eliminate the IALs preceding newline
          # The step forward one char to go to beginning of previous line, not
          # the newline of the previous line.
          prev_line_start = txt.rindex("\n", ial_pos - 5) + 1
          [txt[0...prev_line_start], txt[prev_line_start..-1]]
        else
          # no id, return as is
          [txt, '']
        end
      end

    end
  end
end
