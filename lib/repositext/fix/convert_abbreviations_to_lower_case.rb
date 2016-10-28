class Repositext
  class Fix
    # Finds all instances of A.M., P.M., A.D. and B.C., downcases the text
    # and surrounds it with '*' and adds {: .smcaps}, like so: *a.d.*{: .smcaps}
    # NOTE: this breaks if the replaced abbreviation is nested inside an :em.
    # Example:
    #      *outer em *a.d.*{: .smcaps} outer again*
    #   => <p><em class="smcaps">outer em *a.d.</em> outer again*</p>
    # We will catch this with our validation that looks for leftover kramdown characters.
    class ConvertAbbreviationsToLowerCase

      # @param [String] text
      # @param [String] filename
      # @return [Outcome]
      def self.fix(text, filename)
        t = text.dup
        # NOTE: We need negative lookahead 'D' for B.C. to avoid replacement in A.B.C.D.E...
        t.gsub!(/(?<=\s)A\.M\.|(?<=\s)P\.M\.|A\.D\.|(B\.C\.(?!D))/) { |abbr| "*#{ abbr.unicode_downcase }*{: .smcaps}" }
        Outcome.new(true, { contents: t }, [])
      end

    end
  end
end
