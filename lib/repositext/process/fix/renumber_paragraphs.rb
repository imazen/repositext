class Repositext
  class Process
    class Fix
      class RenumberParagraphs

        # Renumbers numbered paragraphs in content_at_file. Works with placeholders
        # and existing paragraph numbers. Will raise a warning if a paragraph
        # number contains anything other than digits or placeholders.
        # Allows subtitle_marks and gap_marks at beginning of line (in that order).
        # @param content_at_contents [String]
        # @return [Outcome] with `{ contents: new_contents }` as result.
        def self.fix(content_at_contents)
          res = content_at_contents.dup
          p_number = 1 # will be incremented before being used so that we start with 2
          error_messages = []
          res.gsub!(
            /
              ((?<=^\*)|(?<=^@\*)|(?<=^@%\*)|(?<=^%\*)) # asterisk optionally preceded by subtitle mark or gap mark at beginning of line
              ([^\*]*) # inside asterisks
              (?=\*\{:\s*\.pn\}) # trailing asterisk and IAL
            /x,
          ) { |inside_asterisks|
            if inside_asterisks.to_s !~ /\A[\d#]{1,4}\z/
              # Not 1-4 chars, something other than digits or placeholders.
              error_messages << "Invalid paragraph number found: #{ inside_asterisks.inspect }"
            end
            # Replace with next number
            p_number += 1
          }
          Outcome.new(error_messages.empty?, { contents: res }, error_messages)
        end

      end
    end
  end
end
