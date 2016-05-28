class Repositext
  class Process
    class Fix
      class ReplaceInvalidUnicodeLocations

        # Replaces invalid unicode locations using unicode_replacement_mappings
        # @param [String] text
        # @return [String]
        def self.fix(text)
          t = text.dup
          unicode_replacement_mappings.each do |(source, target)|
            t.gsub!(source, target)
          end
          Outcome.new(true, { contents: t }, [])
        end

        # Provides a replacement mapping of unicode codepoints. The first (source)
        # element in each array provides the old (to be replaced) data, and the
        # second (target) provides the new (replacement) codepoint.
        # The `source` element can be either a string or a regex (that can be used
        # as first argument for `#gsub`).
        # The `target` element has to be a string that can be used as second argument
        # for `#gsub`.
        # How to specify unicode codepoints in Ruby strings:
        # `\u` followed by the unicode id in hex.
        # Example: "\u21ba"
        # @return [Array]
        def self.unicode_replacement_mappings
          [
            ["a", "\u21ba"],
          ]
        end

      end
    end
  end
end
