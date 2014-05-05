How to convert straight quotes to typographical ones
====================================================

* Replaces straight quotes with typographical unicode quotes.
* Handles single (`'`) and double (`"`) quotes and apostrophes.
* Prevent replacement by escaping quotes with a backslash, e.g., \".
* Works for english text only.
* Only converts unambiguous cases.
* Ambiguous instances have to be changed by hand.

Replacements
------------

" -> “ - left or opening double quote, unicode \u201c
" -> ” - right or closing double quote, unicode \u201d
' -> ‘ - left or opening single quote, unicode \u2018
' -> ’ - right or closing single quote, unicode \u2019
' -> ’ - apostrophe, unicode \u2019 (same as right single quote)

Resources
---------

* http://practicaltypography.com/straight-and-curly-quotes.html
* list of entities:
    lsquo: '\u2018',
    rsquo: '\u2019',
    ldquo: '\u201c',
    rdquo: '\u201d',
    apostrophy:  '\u2019',
* In English, the apostrophe serves three purposes:
    * The marking of the omission of one or more letters (as in the contraction
      of do not to don’t).
    * The marking of possessive case (as in the eagle's feathers, or in one month's time).
    * The marking by some as plural of written items that are not words established
      in English orthography (as in P's and Q's). (This is considered incorrect
      by others; see Use in forming certain plurals. The use of the apostrophe
      to form plurals of proper words, as in apple’s, banana’s, etc., is
      universally considered incorrect.)
  There are several apostrophe characters defined in Unicode:
    * U+0027 ' apostrophe (HTML: &#39; &apos;) typewriter apostrophe.
    * U+2019 ’ right single quotation mark (HTML: &#8217; &rsquo;).
      Serves as both an apostrophe and closing single quotation mark.
      This is the preferred character to use for apostrophe according to the
      Unicode standard.
  http://en.wikipedia.org/wiki/Apostrophe
* The prime symbol ( ′ ), double prime symbol ( ″ ), and triple prime symbol ( ‴ ),
  etc., are used to designate several different units and for various other
  purposes in mathematics, the sciences, linguistics and music. The prime symbol
  should not be confused with the apostrophe, single quotation mark, acute accent,
  or grave accent;
  http://en.wikipedia.org/wiki/Prime_(symbol)
* http://en.wikipedia.org/wiki/Quotation_mark_glyphs

Algorithm and implementation resources
--------------------------------------

* Ruby port of smartypants
  https://github.com/jmcnevin/rubypants/blob/master/lib/rubypants/core.rb#L245
* Perl writeup and code with some implementation details
  http://www.mobileread.com/forums/showthread.php?t=38193
* http://www.pensee.com/dunham/smartQuotes.html
  Cocoa implementation of smart quotes
* simplistic javascript implementation
  http://www.leancrew.com/all-this/2010/11/smart-quotes-in-javascript/

    // Change straight quotes to curly and double hyphens to em-dashes.
    function smarten(a) {
      a = a.replace(/(^|[-\u2014\s(\["])'/g, "$1\u2018");       // opening singles
      a = a.replace(/'/g, "\u2019");                            // closing singles & apostrophes
      a = a.replace(/(^|[-\u2014/\[(\u2018\s])"/g, "$1\u201c"); // opening doubles
      a = a.replace(/"/g, "\u201d");                            // closing doubles
      a = a.replace(/--/g, "\u2014");                           // em-dashes
      return a
    };

* smart quotes implementation of pandoc.
  https://github.com/jgm/pandoc/blob/ced8be1d080019f56033c8200974598910985dc4/src/Text/Pandoc/Parsing.hs
* Good thread on SO, read all the answers!
  http://stackoverflow.com/questions/509685/ideas-for-converting-straight-quotes-to-curly-quotes
* A java library that implements this
  https://code.google.com/p/smartquotes/source/browse/trunk/src/main/java/net/mattryall/smartquotes/SmartQuotes.java
