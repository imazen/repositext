require_relative '../../../helper'

class Repositext
  class Process
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
          [':…%word', ':%…word'],
          ['word…%word', 'word…%word'],
          ["a‘%word'", "%a‘word'"], # single open quote
          ['(word1)…*%word2', '(word1)…%*word2'],
          ['word %word%word word', 'word %wordword word'],
          ['word %word%-word word', 'word %word-word word'],
          ['word—w%ord word', 'word—%word word'],
          ['儋圚%儋圚', '儋圚%儋圚'],
          ['word word word%. ', 'word word %word. '],
          ['word. %w%*ord* word', 'word. %w*ord* word'],
          ['儋圚（%儋圚', '儋圚%（儋圚'],
          ['圚《%儋', '圚%《儋'],
        ].each do |(txt, xpect)|
          it "handles #{ txt.inspect }" do
            o = AdjustGapMarkPositions.fix(txt, '_', Repositext::Language::English)
            o.result[:contents].must_equal(xpect)
          end
        end

        describe '#fix_chinese_chars' do
          [
            ['word%’word', 'word%’word'],
            ['儋%’圚', '儋’%圚'],
          ].each do |(txt, xpect)|
            it "handles #{ txt.inspect }" do
              r = AdjustGapMarkPositions.send(:fix_chinese_chars, txt, Repositext::Language::English)
              r.must_equal(xpect)
            end
          end
        end

      end
    end
  end
end
