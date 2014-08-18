class Repositext
  class Utils
    # Entity encodes legitimate special characters
    class EntityEncoder

      def self.encode(text)
        text.gsub(/[\u00A0\u2011\u2028\u202F\uFEFF]/) { |match|
          sprintf('&#x%04X;', match.codepoints.first)
        }
      end

    end
  end
end
