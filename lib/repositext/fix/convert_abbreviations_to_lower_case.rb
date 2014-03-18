class Repositext
  class Fix
    class ConvertAbbreviationsToLowerCase

      # Finds all instances of A.M., P.M., A.D. and B.C., downcases the text
      # and surrounds it with '*' and adds {: .smcaps}, like so: *a.d.*{: .smcaps}
      # TODO: make sure that none of these are nested inside an :em
      # @param[String] text
      # @return[Outcome]
      def self.fix(text)
        t = text.dup
        t.gsub!(/A\.M\.|P\.M\.|A\.D\.|B\.C\./) { |abbr| "*#{ abbr.downcase }*{: .smcaps}" }
        Outcome.new(true, { contents: text }, [])
      end

    end
  end
end
