require_relative '../../helper'

describe Repositext::Merge::TitlesFromFolioRoundtripCompareIntoContentAt do

  describe '#extract_title' do
    [
      ['1 title', 'title'],
      ['1abc title word word', 'title word word'],
      [' 1 title', 'title'],
      [' 1abc title word word', 'title word word'],
    ].each do |test_string, xpect|
      it "handles #{ test_string.inspect }" do
        Repositext::Merge::TitlesFromFolioRoundtripCompareIntoContentAt.send(
          :extract_title, test_string
        ).must_equal(xpect)
      end
    end
  end

  describe 'merge_title_into_content_at' do
    [
      ['new_title', '# *Old title*', '# *new_title*'],
    ].each do |title, content_at, xpect|
      it "handles #{ title.inspect }" do
        Repositext::Merge::TitlesFromFolioRoundtripCompareIntoContentAt.send(
          :merge_title_into_content_at, title, content_at
        ).result.must_equal(xpect)
      end
    end
  end

end
