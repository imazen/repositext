class Repositext
  class Fix
    class RemoveUnderscoresInsideFolioParagraphNumbers

      # Removes underscores inside folio paragraph numbers
      # @param[String] text
      # @return[Outcome]
      def self.fix(text)
        t = text.dup
        # Example: *14\_*{: .pn} => *14*{: .pn}
        # Match '\_' preceded by asterisk and number and followed by asterisk and .pn IAL
        t.gsub!(/(\*\d+)\\_(?=\*\{: \.pn)/, '\1')
        Outcome.new(true, { contents: t }, [])
      end
    end
  end
end
