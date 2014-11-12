require_relative '../../helper'

class Repositext
  class Fix
    describe AdjustGapMarkPositions do

      [
        ['*%word*', '%*word*'],
        ['“%word', '%“word'],
        ["‘%word", "%‘word"],
        ['(%word)', '%(word)'],
        ['[%word]', '%[word]'],
        ['*“‘([%word]', '%*“‘([word]'],
        ['* %word*', '* %word*'],
        [' …%word', ' %…word'],
        ['word…%word', 'word…%word'],
        ["a‘%word'", "%a‘word'"], # single open quote
        ["a’%word'", "%a’word'"], # apostrophe
        ['(word1)…*%word2', '(word1)…%*word2'],
        ['word %word%word word', 'word %wordword word'],
        ['word %word%-word word', 'word %word-word word'],
        ['word—w%ord word', 'word—%word word'],
        ['儋圚%儋圚', '儋圚%儋圚'],
        ['word word word%. ', 'word word %word. '],
        ['word. %w%*ord* word', 'word. %w*ord* word'],
        ['儋圚（%儋圚', '儋圚%（儋圚'],
      ].each do |(txt, xpect)|
        it "handles #{ txt.inspect }" do
          o = AdjustGapMarkPositions.fix(txt, '_')
          o.result[:contents].must_equal(xpect)
        end
      end

    end
  end
end
