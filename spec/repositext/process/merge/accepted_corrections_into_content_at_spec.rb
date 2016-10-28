require_relative '../../../helper'

class Repositext
  class Process
    class Merge
      describe AcceptedCorrectionsIntoContentAt do

        describe 'compute_fuzzy_after_matches_count' do
          [
            [{ :becomes => 'word1 word2' }, 'word1x word2', 0],
            [{ :becomes => 'word1 word2' }, 'word1 word2', 1],
            [{ :becomes => 'word1 word2' }, 'word1 %word2', 1],
            [{ :becomes => '%word1 word2' }, 'word1 word2', 1],
            [{ :becomes => '%word1 %word2' }, 'word1 word2 @word1 %word2 %word1 @word2 @word1 @word2', 4],
          ].each do |correction, test_string, xpect|
            it "handles #{ correction.inspect }" do
              AcceptedCorrectionsIntoContentAt.send(
                :compute_fuzzy_after_matches_count, correction, test_string
              ).must_equal(xpect)
            end
          end
        end

        describe 'compute_merge_action' do
          [
            [
              :auto,
              { :reads => 'word1 word2', :becomes => 'no match' },
              "before word1 word2 after",
              [:apply_automatically],
            ],
            [
              :auto,
              { :reads => 'no match', :becomes => 'no match' },
              "before word1 word2 after",
              [:do_nothing],
            ],
            [
              :auto,
              { :reads => '_', :no_change => true },
              "before word1 word2 after",
              [:do_nothing],
            ],
            [
              :manual,
              { :reads => 'no match', :becomes => 'word1 word2' },
              "before word1 word2 after",
              [:report_already_applied, 'Exact'],
            ],
            [
              :manual,
              { :reads => 'no match', :becomes => '%word1 @word2' },
              "before word1 word2 after",
              [:report_already_applied, '~Fuzzy (ignoring gap_marks and subtitle_marks)'],
            ],
            [
              :manual,
              { :reads => 'no match', :becomes => 'no match' },
              "before word1 word2 after",
              [:apply_manually, :no_match_found],
            ],
            [
              :manual,
              { :reads => 'word', :becomes => 'no match' },
              "before word1 word2 after",
              [:apply_manually, :multiple_matches_found],
            ],
          ].each do |strategy, correction, relevant_paragraphs, xpect|
            it "handles #{ correction.inspect }" do
              AcceptedCorrectionsIntoContentAt.send(
                :compute_merge_action, strategy, correction, relevant_paragraphs
              ).must_equal(xpect)
            end
          end
        end

        describe 'extract_corrections' do
          # This is tested in Repositext::Process::Extract::SubmittedSpotCorrections
        end

        describe 'merge_auto' do
          # NOTE: Integration method, no test
        end

        describe 'merge_corrections_into_content_at' do
          # NOTE: Integration method, no test
        end

        describe 'merge_manually' do
          # NOTE: Integration method, no test
        end

        describe 'open_in_sublime' do
          # NOTE: Integration method, no test
        end

        describe 'replace_perfect_match!' do

          let(:corrected_at){
            [
              '# Header',
              'First paragraph without a number',
              '*2*{: .pn} second paragraph',
              '@*3*{: .pn} third paragraph ',
              '',
            ].join("\n\n")
          }

          [
            [
              {
                paragraph_number: '2',
                reads: 'second paragraph',
                becomes: 'second paragraph added',
              },
              "\n*2*{: .pn} second paragraph\n",
              [
                '# Header',
                'First paragraph without a number',
                '*2*{: .pn} second paragraph added',
                '@*3*{: .pn} third paragraph ',
                '',
              ].join("\n\n")
            ], # regular case
            [
              {
                paragraph_number: '3',
                reads: 'third paragraph',
                becomes: 'third paragraph added',
              },
              "\n@*3*{: .pn} third paragraph ",
              [
                '# Header',
                'First paragraph without a number',
                '*2*{: .pn} second paragraph',
                '@*3*{: .pn} third paragraph added ',
                '',
              ].join("\n\n")
            ], # paragraph is preceded with subtitle_mark
          ].each do |correction, relevant_paragraphs, xpect|
            it "handles #{ correction.inspect }" do
              report_lines = []
              AcceptedCorrectionsIntoContentAt.send(
                :replace_perfect_match!, correction, corrected_at, relevant_paragraphs, report_lines
              )
              corrected_at.must_equal(xpect)
            end
          end
        end

        describe 'manually_edit_correction!' do
          # NOTE: Integration method, no test
        end

      end
    end
  end
end
