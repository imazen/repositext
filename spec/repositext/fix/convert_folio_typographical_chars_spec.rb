require_relative '../../helper'

describe Repositext::Fix::ConvertFolioTypographicalChars do

  describe 'Elipses' do
    [
      ['Mrs. Ford, Mrs.... I think', 'Mrs. Ford, Mrs.… I think'],
      ['-I think... I thought', '-I think… I thought'],
    ].each do |(txt, xpect)|
      it "handles #{ txt.inspect }" do
        o = Repositext::Fix::ConvertFolioTypographicalChars.fix(txt, '_')
        o.result[:contents].must_equal(xpect)
      end
    end
  end

  describe 'Apostrophes' do
    [
      [%(word 'cause word), %(word ’cause word)],
      [%(word. 'Cause word), %(word. ’Cause word)],
      [%(word 'course word), %(word ’course word)],
      [%(word 'fore word), %(word ’fore word)],
      [%(word 'kinis word), %(word ’kinis word)],
      [%(word 'less word), %(word ’less word)],
      [%(word 'till word), %(word ’till word)],
      [%(word '77 word), %(word ’77 word)],
      [%(word 80's word), %(word 80’s word)],
      [%(word 80'word), %(word 80'word)],
      [%(word word's word), %(word word’s word)],
      [%(P's and Q's), %(P’s and Q’s)],
      [%(word ma'am word), %(word ma’am word)],
      [%(word o'clock word), %(word o’clock word)],
      [%(word he'd word), %(word he’d word)],
      [%(word i'd word), %(word i’d word)],
      [%(word i'd word), %(word i’d word)],
      [%(word it'd word), %(word it’d word)],
      [%(word she'd word), %(word she’d word)],
      [%(word that'd word), %(word that’d word)],
      [%(word there'd word), %(word there’d word)],
      [%(word they'd word), %(word they’d word)],
      [%(word we'd word), %(word we’d word)],
      [%(word what'd word), %(word what’d word)],
      [%(word where'd word), %(word where’d word)],
      [%(word who'd word), %(word who’d word)],
      [%(word you'd word), %(word you’d word)],
      [%(word he'll word), %(word he’ll word)],
      [%(word i'll word), %(word i’ll word)],
      [%(word it'll word), %(word it’ll word)],
      [%(word she'll word), %(word she’ll word)],
      [%(word that'll word), %(word that’ll word)],
      [%(word there'll word), %(word there’ll word)],
      [%(word they'll word), %(word they’ll word)],
      [%(word we'll word), %(word we’ll word)],
      [%(word you'll word), %(word you’ll word)],
      [%(word i'm word), %(word i’m word)],
      [%(word they're word), %(word they’re word)],
      [%(word we're word), %(word we’re word)],
      [%(word what're word), %(word what’re word)],
      [%(word who're word), %(word who’re word)],
      [%(word you're word), %(word you’re word)],
      [%(word ain't word), %(word ain’t word)],
      [%(word aren't word), %(word aren’t word)],
      [%(word can't word), %(word can’t word)],
      [%(word couldn't word), %(word couldn’t word)],
      [%(word didn't word), %(word didn’t word)],
      [%(word doesn't word), %(word doesn’t word)],
      [%(word don't word), %(word don’t word)],
      [%(word hadn't word), %(word hadn’t word)],
      [%(word hasn't word), %(word hasn’t word)],
      [%(word haven't word), %(word haven’t word)],
      [%(word isn't word), %(word isn’t word)],
      [%(word mustn't word), %(word mustn’t word)],
      [%(word oughtn't word), %(word oughtn’t word)],
      [%(word shouldn't word), %(word shouldn’t word)],
      [%(word wasn't word), %(word wasn’t word)],
      [%(word weren't word), %(word weren’t word)],
      [%(word won't word), %(word won’t word)],
      [%(word wouldn't word), %(word wouldn’t word)],
      [%(word could've word), %(word could’ve word)],
      [%(word had've word), %(word had’ve word)],
      [%(word i've word), %(word i’ve word)],
      [%(word might've word), %(word might’ve word)],
      [%(word must've word), %(word must’ve word)],
      [%(word ought've word), %(word ought’ve word)],
      [%(word should've word), %(word should’ve word)],
      [%(word they've word), %(word they’ve word)],
      [%(word we've word), %(word we’ve word)],
      [%(word who've word), %(word who’ve word)],
      [%(word would've word), %(word would’ve word)],
      [%(word you've word), %(word you’ve word)],
    ].each do |(txt, xpect)|
      it "handles #{ txt.inspect }" do
        o = Repositext::Fix::ConvertFolioTypographicalChars.fix(txt, '_')
        o.result[:contents].must_equal(xpect)
      end
    end
  end

  describe 'Quotes' do
    [
      [%(word, "word don't…"—Ed.]), %(word, “word don’t…”—Ed.])],
      [%(word, "word word", word), %(word, “word word”, word)],
      [%( ["Word."] ), %( [“Word.”] )],
      [%([word word, "Word word, word word…?…"—Ed.]), %([word word, “Word word, word word…?…”—Ed.])],
      [%([Word word,"Word."—Ed.]), %([Word word,“Word.”—Ed.])],
      [%(word, "Word [Word word—Ed.]" Word), %(word, “Word [Word word—Ed.]” Word)],
      [%([Word word,"Word word, word Word.”—Ed.]), %([Word word,“Word word, word Word.”—Ed.])],
      [%(word, "word, word [Word word.—Ed.]" word), %(word, “word, word [Word word.—Ed.]” word)],
      [%(word, "[Word word—Ed.]" word), %(word, “[Word word—Ed.]” word)],
      [%(word, "Word, word—"\n), %(word, “Word, word—”\n)],
      [%(^^^ {: .rid #12345678 kpn="042"}), %(^^^ {: .rid #12345678 kpn="042"})],
    ].each do |(txt, xpect)|
      it "handles #{ txt.inspect }" do
        o = Repositext::Fix::ConvertFolioTypographicalChars.fix(txt, '_')
        o.result[:contents].must_equal(xpect)
      end
    end
  end

end
