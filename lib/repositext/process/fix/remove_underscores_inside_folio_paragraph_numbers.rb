class Repositext
  class Process
    class Fix
      # Removes underscores inside folio paragraph numbers
      class RemoveUnderscoresInsideFolioParagraphNumbers

        # @param [String] text
        # @param [String] filename
        # @return [Outcome]
        def self.fix(text, filename)
          t = text.dup
          # Example: *14\_*{: .pn} => *14*{: .pn}
          # Match '\_' preceded by asterisk and number and followed by asterisk and .pn IAL
          t.gsub!(/(\*\d+)\\_(?=\*\{: \.pn)/, '\1')
          Outcome.new(true, { contents: t }, [])
        end
      end
    end
  end
end
