class Repositext
  class Fix
    class ConvertFolioTypographicalChars

      # Converts certain characters in text to proper typographical marks.
      # @param[String] text
      # @return[Outcome]
      def self.fix(text)
        #Abbreviations are valid instances we need to handle
        text = text.gsub /(Mrs?\.)\.\.\./i, "\1…"
        #Replace 3, but not 4 dots with ellipsis
        text.gsub! /\.{3}(?!\.)/, "…"

        emdash = "—"
        opendquote = "“"
        closedquote = "”"
        #Create em-dashes
        text.gsub! /\-\-/, emdash

        #Opening quotes with space on the left
        #before: space, tab, or beginning of line
        #after: letter, number, asterisk, open parenthesis, backslash, ellipsis, hyphen, or emdash.
        text.gsub! /(?<=[ \t\n])"(?=[A-Za-z0-9'\*\(\-…—])/, opendquote


        #before: mdash, open parenthesis, open square bracket, asterisk
        #after: letter
        text.gsub! /(?<=[—\(\[\-\*])"(?=[a-zA-Z])/, opendquote

        #Closing quotes



        #before: Question mark, period, comma, letter, apostrophe, exclamation mark, asterisk,
        #after:  space, tab, end of line, em dash, hyphen, colon, semicolon, backslash, questionmark, exclamation, close paren
        text.gsub! /(?<=[\?\.,a-zA-Z\'\!\*])"(?=[ \t\n—\-\:\\\\?\!;\)])/, closedquote


        #before: colon, semicolon, ellipsis
        #after: space, tab, newline
        text.gsub! /(?<=[;:…])"(?=[ \t\n])/, closedquote

        #before: period, closing square bracket, exclamation, question mark
        #after: ellipsis or single quotes
        text.gsub! /(?<=[\.\]\?\!])"(?=[…'])/, closedquote


        #before: letter
        #after: ellipsis, period
        text.gsub! /(?<=[a-zA-Z])"(?=[…\.])/, closedquote



        #[^=]"[^}]
        remaining = text.scan(/[^=]"[^\}]/)

        if remaining.length > 0
          message = " #{remaining.length} double quotes remaining: " + (remaining.take(5).map{|s| s.inspect} * "  ")
        else
          message = nil
        end

        Outcome.new(true, { contents: text }, [message].compact)
      end
    end
  end
end
