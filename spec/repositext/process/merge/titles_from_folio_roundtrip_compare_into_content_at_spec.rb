require_relative '../../../helper'

class Repositext
  class Process
    class Merge
      describe TitlesFromFolioRoundtripCompareIntoContentAt do

        describe '#extract_title' do
          [
            ['1 title', 'title'],
            ['1abc title word word', 'title word word'],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              TitlesFromFolioRoundtripCompareIntoContentAt.send(
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
              TitlesFromFolioRoundtripCompareIntoContentAt.send(
                :merge_title_into_content_at, title, content_at
              ).result.must_equal(xpect)
            end
          end
        end

      end
    end
  end
end
