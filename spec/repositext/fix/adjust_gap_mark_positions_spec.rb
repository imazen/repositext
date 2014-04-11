require_relative '../../helper'

describe Repositext::Fix::AdjustGapMarkPositions do

  [
    ['*%word*', '%*word*'],
    ['"%word"', '%"word"'],
    ["'%word'", "%'word'"],
    ['(%word)', '%(word)'],
    ['[%word]', '%[word]'],
    ['*"\'([%word]', '%*"\'([word]'],
    ['* %word*', '* %word*'],
    [' …%word', ' %…word'],
    ['word…%word', 'word…%word'],
    ["a'%word'", "a%'word'"],
    ['(word1)…*%word2', '(word1)…%*word2'],
    ['word %word%word word', 'word %wordword word'],
    ['word %word%-word word', 'word %word-word word'],
    ['little—t%hat little', 'little—%that little'],
    ['in every age%. ', 'in every %age. ']
  ].each do |(txt, xpect)|
    it "handles #{ txt.inspect }" do
      o = Repositext::Fix::AdjustGapMarkPositions.fix(txt)
      o.result[:contents].must_equal(xpect)
    end
  end

end
