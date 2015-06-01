# encoding UTF-8
require_relative '../../helper'

class Repositext
  class Report
    describe InvalidTypographicQuotes do

      [
        [%(matching ‘s_quotes’), []],
        [%(matching “d_quotes”), []],
        [
          %(sequence of two ‘s_quote_open‘ on single line),
          [['_', [{ line: 1 , excerpt: %(sequence of two ‘s_quote_open‘) }]]]
        ],
        [
          %(sequence of two ‘s_quote_open\nword‘ on multiple lines),
          [['_', [{ line: 2 , excerpt: %(sequence of two ‘s_quote_open\\nword‘) }]]]
        ],
        [
          %(sequence of two “d_quote_open“ on single line),
          [['_', [{ line: 1 , excerpt: %(sequence of two “d_quote_open“) }]]]
        ],
        [
          %(sequence of two “d_quote_open\nword“ on multiple lines),
          []
        ],
        [
          %(sequence of two ”d_quote_close” on single line),
          [['_', [{ line: 1 , excerpt: %(sequence of two ”d_quote_close”) }]]]
        ],
        [
          %(sequence of two ”d_quote_close\nword” on multiple lines),
          [['_', [{ line: 2 , excerpt: %(sequence of two ”d_quote_close\\nword”) }]]]
        ],
        [
          %(sequence of two “d_quote_open’ word“ with apostrophe inbetween),
          [['_', [{ line: 1 , excerpt: %(sequence of two “d_quote_open’ word“) }]]]
        ],
        [
          %(sequence of two ”d_quote_close’ word” with apostrophe inbetween),
          [['_', [{ line: 1 , excerpt: %(sequence of two ”d_quote_close’ word”) }]]]
        ],
      ].each do |(txt, xpect)|
        it "handles #{ txt.inspect }" do
          r = InvalidTypographicQuotes.new(0)
          r.process(txt, '_')
          r.results.must_equal(xpect)
        end
      end

    end
  end
end
