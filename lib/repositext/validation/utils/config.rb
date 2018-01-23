class Repositext
  class Validation
    # Holds configuration
    class Config

      # Array of code points that are considered invalid in all of Repositext::Validation.
      # This is the largest common denominator shared by all validations. Specific
      # Validators may add more items to this list for stricter requirements.
      # E.g., PT Syntax adds the '%' and '@' characters.
      # This catches any non-keyboard, invisible, spacing, or control characters.
      INVALID_CODE_POINTS = [
        0x0000, # null
        0x0001, # start of heading
        0x0002, # start of text
        0x0003, # end of text
        0x0004, # end of transmission
        0x0005, # enquiry
        0x0006, # acknowledge
        0x0007, # bell
        0x0008, # backspace
      # 0x0009 horizontal tab (character tabulation)
      # 0x000A line feed
        0x000B, # vertical tab (line tabulation)
        0x000C, # form feed
      # 0x000D carriage return
        0x000E, # shift out (locking shift one)
        0x000F, # shift in (locking shift zero)
        0x0010, # data link escape
        0x0011, # device control one
        0x0012, # device control two
        0x0013, # device control three
        0x0014, # device control four
        0x0015, # negative acknowledge
        0x0016, # synchronous idle
        0x0017, # end of transmission block
        0x0018, # cancel
        0x0019, # end of medium
        0x001A, # substitute
        0x001B, # escape
        0x001C, # information separator four (file separator)
        0x001D, # information separator three (group separator)
        0x001E, # information separator two (record separator)
        0x001F, # information separator one (unit separator)
      # 0x0020 space
        0x0027, # apostrophe
        0x007E, # ~ tilde
        0x007F, # delete
        0x0080, # <control>
        0x0081, # <control>
        0x0082, # break permitted here
        0x0083, # no break here
        0x0084, # formerly known as index
        0x0085, # next line
        0x0086, # start of selected area
        0x0087, # end of selected area
        0x0088, # character tabulation set
        0x0089, # character tabulation with justification
        0x008A, # line tabulation set
        0x008B, # partial line forward
        0x008C, # partial line backward
        0x008D, # reverse line feed
        0x008E, # single shift two
        0x008F, # single shift three
        0x0090, # device control string
        0x0091, # private use one
        0x0092, # private use two
        0x0093, # set transmit state
        0x0094, # cancel character
        0x0095, # message waiting
        0x0096, # start of guarded area
        0x0097, # end of guarded area
        0x0098, # start of string
        0x0099, # <control>
        0x009A, # single character introducer
        0x009B, # control sequence introducer
        0x009C, # string terminator
        0x009D, # operating system command
        0x009E, # privacy message
        0x009F, # application program command
      # 0x00A0 nonbreaking space
        0x00AD, # discretionary hyphen (soft hyphen)
        0x2000, # en quad
        0x2001, # em quad
        0x2002, # en space
        0x2003, # em space
        0x2004, # three-per-em space
        0x2005, # four-per-em space
        0x2006, # six-per-em space
        0x2007, # figure space
        0x2008, # punctuation space
        0x2009, # thin space
        0x200A, # hair space
      # TODO: Change the code point 200B to be configurable so it is only accpetable for Khmer.
      # 0x200B, # discretionary line break (zero width space)
      # 0x200C, # zero width nonjoiner
      # 0x200D, # zero width joiner (used in some indian languages)
        0x200E, # left-to-right mark
        0x200F, # right-to-left mark
      # 0x2011 nonbreaking hyphen
      # 0x2028 line separator (used in IDML stories)
        0x2029, # paragraph separator
        0x202A, # left-to-right embedding
        0x202B, # right-to-left embedding
        0x202C, # pop directional formatting
        0x202D, # left-to-right override
        0x202E, # right-to-left override
      # 0x202F, # narrow no-break space
        0x205F, # medium mathematical space
        0x2060, # word joiner
        0x2061, # function application
        0x2062, # invisible times
        0x2063, # invisible separator
        0x2064, # invisible plus
        0x2066, # left-to-right isolate
        0x2067, # right-to-left isolate
        0x2068, # first strong isolate
        0x2069, # pop directional isolate
        0x206A, # inhibit symmetric swapping (deprecated)
        0x206B, # activate symmetric swapping (deprecated)
        0x206C, # inhibit arabic form shaping (deprecated)
        0x206D, # activate arabic form shaping (deprecated)
        0x206E, # national digit shapes (deprecated)
        0x206F, # nominal digit shapes (deprecated)
        0x3000, # ideographic space
      # 0xD800..0xDBFF <high surrogate area> - Considered invalid unicode range for regex
      # 0xDC00..0xDFFF <low surrogate area> - Considered invalid unicode range for regex
        0xFD90, # <reserved>
        0xFD91, # <reserved>
        0xFDD0, # <not a character>
        0xFDD1, # <not a character>
        0xFDD2, # <not a character>
        0xFDD3, # <not a character>
        0xFDD4, # <not a character>
        0xFDD5, # <not a character>
        0xFDD6, # <not a character>
        0xFDD7, # <not a character>
        0xFDD8, # <not a character>
        0xFDD9, # <not a character>
        0xFDDA, # <not a character>
        0xFDDB, # <not a character>
        0xFDDC, # <not a character>
        0xFDDD, # <not a character>
        0xFDDE, # <not a character>
        0xFDDF, # <not a character>
        0xFDE0, # <not a character>
        0xFDE1, # <not a character>
        0xFDE2, # <not a character>
        0xFDE3, # <not a character>
        0xFDE4, # <not a character>
        0xFDE5, # <not a character>
        0xFDE6, # <not a character>
        0xFDE7, # <not a character>
        0xFDE8, # <not a character>
        0xFDE9, # <not a character>
        0xFDEA, # <not a character>
        0xFDEB, # <not a character>
        0xFDEC, # <not a character>
        0xFDED, # <not a character>
        0xFDEE, # <not a character>
        0xFDEF, # <not a character>
        0xFE00, # <variation selectors supplement>
        0xFE01, # <variation selectors supplement>
        0xFE02, # <variation selectors supplement>
        0xFE03, # <variation selectors supplement>
        0xFE04, # <variation selectors supplement>
        0xFE05, # <variation selectors supplement>
        0xFE06, # <variation selectors supplement>
        0xFE07, # <variation selectors supplement>
        0xFE08, # <variation selectors supplement>
        0xFE09, # <variation selectors supplement>
        0xFE0A, # <variation selectors supplement>
        0xFE0B, # <variation selectors supplement>
        0xFE0C, # <variation selectors supplement>
        0xFE0D, # <variation selectors supplement>
        0xFE0E, # <variation selectors supplement>
        0xFE0F, # <variation selectors supplement>
      # 0xFEFF zero width no-break space
        0xFFF0, # <reserved>
        0xFFF1, # <reserved>
        0xFFF2, # <reserved>
        0xFFF3, # <reserved>
        0xFFF4, # <reserved>
        0xFFF5, # <reserved>
        0xFFF6, # <reserved>
        0xFFF7, # <reserved>
        0xFFF8, # <reserved>
        0xFFF9, # interlinear annotation anchor
        0xFFFA, # interlinear annotation separator
        0xFFFB, # interlinear annotation terminator
        0xFFFC, # object replacement character
        0xFFFD, # replacement character
        0xFFFE, # <not a character>
        0xFFFF  # <not a character>
      ].freeze
      # Convert array of code points into array of regexes that uses ranges
      # where possible.
      # NOTE: regex for valid xml chars: http://stackoverflow.com/questions/397250/unicode-regex-invalid-xml-characters
      # NOTE: /[[:cntrl:]]/ is too broad. E.g., it contains "\n"
      # NOTE on performance: using ranges rather than individual code points reduced
      #     total validation runtime for set of 100+ IDML docs from 100 sec to 60 sec.
      INVALID_CHARACTER_REGEXES = INVALID_CODE_POINTS.merge_adjacent_items_into_ranges(true).map { |e|
        case e
        when Integer
          Regexp.new("\\u#{ sprintf('%04X', e) }")
        when Range
          Regexp.new("[\\u#{ sprintf('%04X', e.min) }-\\u#{ sprintf('%04X', e.max) }]")
        else
          raise(ArgumentError.new("Invalid code point: #{ e.inspect }"))
        end
      }.freeze
    end
  end
end
