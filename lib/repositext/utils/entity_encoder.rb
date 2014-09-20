class Repositext
  class Utils
    # Entity encodes legitimate special characters
    class EntityEncoder

      # Encode the unicode codepoints that are allowed per
      # Repositext::Validation::Config::INVALID_CODE_POINTS
      def self.encode(text)
        text.gsub(/[\u00A0\u2011\u2028\u202F\uFEFF]/) { |match|
          sprintf('&#x%04X;', match.codepoints.first)
        }
      end

      # Decode the unicode codepoints that are allowed per
      # Repositext::Validation::Config::INVALID_CODE_POINTS
      def self.decode(text)
        text.gsub(/\\?&\\?#x(00A0|2011|2028|202F|FEFF)\;/) { |match|
          [$1.hex].pack("U") # convert hex unicode to char
        }
      end

    end
  end
end
