require_relative '../../helper'

class Repositext
  class Merge
    describe AcceptedCorrectionsIntoContentAt do

      describe 'compute_first_para_num' do
        [
          ["*1*{: .pn} the first para\n\n*141*{: .pn}", '1'],
          ["*2*{: .pn} the first para\n\n*141*{: .pn}", '1'],
          ["@*3*{: .pn} the first para\n\n*141*{: .pn}", '2'],
          ["%*4*{: .pn} the first para\n\n*141*{: .pn}", '3'],
          ["@%*5*{: .pn} the first para\n\n*141*{: .pn}", '4'],
        ].each do |test_string, xpect|
          it "handles #{ test_string.inspect }" do
            AcceptedCorrectionsIntoContentAt.send(
              :compute_first_para_num, test_string
            ).must_equal(xpect)
          end
        end
      end

      describe 'compute_last_para_num' do
        [
          ["*1*{: .pn} the first para\n\n*141*{: .pn}", '141'],
          ["*1*{: .pn} the first para\n\n@*142*{: .pn}", '142'],
          ["*1*{: .pn} the first para\n\n%*143*{: .pn}", '143'],
          ["*1*{: .pn} the first para\n\n@%*144*{: .pn}", '144'],
          ["*1*{: .pn} the first para\n\n*145a*{: .pn}", '145a'],
        ].each do |test_string, xpect|
          it "handles #{ test_string.inspect }" do
            AcceptedCorrectionsIntoContentAt.send(
              :compute_last_para_num, test_string
            ).must_equal(xpect)
          end
        end
      end

      describe 'compute_fuzzy_after_matches_count' do
        [
          [{ :after => 'word1 word2' }, 'word1x word2', 0],
          [{ :after => 'word1 word2' }, 'word1 word2', 1],
          [{ :after => 'word1 word2' }, 'word1 %word2', 1],
          [{ :after => '%word1 word2' }, 'word1 word2', 1],
          [{ :after => '%word1 %word2' }, 'word1 word2 @word1 %word2 %word1 @word2 @word1 @word2', 4],
        ].each do |correction, test_string, xpect|
          it "handles #{ correction.inspect }" do
            AcceptedCorrectionsIntoContentAt.send(
              :compute_fuzzy_after_matches_count, correction, test_string
            ).must_equal(xpect)
          end
        end
      end

      describe 'compute_line_number_from_paragraph_number' do
        [
          [3, "line 1\nline 2\nline 3\n*3*{: .pn} line 4", 4], # paragraph_number as integer
          ['3', "line 1\nline 2\nline 3\n*3*{: .pn} line 4", 4], # paragraph_number as string
          ['1', "line 1\nline 2\nline 3\n*1*{: .pn} line 4", 1], # first paragraph starts on line one
          ['3', "line 1\nline 2\nline 3\n@*3*{: .pn} line 4", 4], # paragraph_number with subtitle_mark
        ].each do |paragraph_number, test_string, xpect|
          it "handles #{ test_string.inspect }" do
            AcceptedCorrectionsIntoContentAt.send(
              :compute_line_number_from_paragraph_number, paragraph_number, test_string
            ).must_equal(xpect)
          end
        end
      end

      describe 'compute_merge_action' do
        [
          [
            :auto,
            { :before => 'word1 word2', :after => 'no match' },
            "before word1 word2 after",
            [:apply_automatically],
          ],
          [
            :auto,
            { :before => 'no match', :after => 'no match' },
            "before word1 word2 after",
            [:do_nothing],
          ],
          [
            :auto,
            { :before => '_', :no_change => true },
            "before word1 word2 after",
            [:do_nothing],
          ],
          [
            :manual,
            { :before => 'no match', :after => 'word1 word2' },
            "before word1 word2 after",
            [:report_already_applied, 'Exact'],
          ],
          [
            :manual,
            { :before => 'no match', :after => '%word1 @word2' },
            "before word1 word2 after",
            [:report_already_applied, '~Fuzzy (ignoring gap_marks and subtitle_marks)'],
          ],
          [
            :manual,
            { :before => 'no match', :after => 'no match' },
            "before word1 word2 after",
            [:apply_manually, :no_match_found],
          ],
          [
            :manual,
            { :before => 'word', :after => 'no match' },
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

      describe 'dynamic_paragraph_number_regex' do
        [
          [1, "line 1\n\n*2*{: .pn}\n\n*3*{: .pn}", /\A/], # first paragraph
          [2, "line 1\n\n*2*{: .pn}\n\n*3*{: .pn}", /\n[@%]{0,2}\*2\*\{\:\s\.pn\}/], # subsequent paragraph
        ].each do |paragraph_number, test_string, xpect|
          it "handles #{ test_string.inspect }" do
            AcceptedCorrectionsIntoContentAt.send(
              :dynamic_paragraph_number_regex, paragraph_number, test_string
            ).must_equal(xpect)
          end
        end
      end

      describe 'extract_corrections' do

        [
          [
            %(
              Simplest case: single line `Reads` and `Becomes`

              1. Page 7, Paragraph 47, Line 4
              Reads: word1 word2 word3 word4 word5
              Becomes: word1 (word2) word3 word4 word5

              2. Page 8, Paragraphs 54-57, Line 7
              Reads: word1 word2 word3
              Becomes: word1 word2modified word3

              3. Page 27, Paragraph 177, Lines 6-7
              Reads: word1 word2 word3
              Becomes: word1 word2 word4added word3
            ),
            [
              {
                :after=>"word1 (word2) word3 word4 word5",
                :before=>"word1 word2 word3 word4 word5",
                :correction_number=>"1",
                :first_line=>"1. Page 7, Paragraph 47, Line 4",
                :paragraph_number=>"47"
              }, {
                :after=>"word1 word2modified word3",
                :before=>"word1 word2 word3",
                :correction_number=>"2",
                :first_line=>"2. Page 8, Paragraphs 54-57, Line 7",
                :paragraph_number=>"54"
              }, {
                :after=>"word1 word2 word4added word3",
                :before=>"word1 word2 word3",
                :correction_number=>"3",
                :first_line=>"3. Page 27, Paragraph 177, Lines 6-7",
                :paragraph_number=>"177"
              }
            ]
          ],
          [
            %(
              Case: `Becomes` overrides `Submitted`

              1. Page 7, Paragraph 47, Line 4
              Reads: word1 word2 word3 word4 word5
              Submitted: word1 [word2] word3 word4 word5
              Becomes: word1 (word2) word3 word4 word5
            ),
            [
              {
                :after=>"word1 (word2) word3 word4 word5",
                :before=>"word1 word2 word3 word4 word5",
                :correction_number=>"1",
                :first_line=>"1. Page 7, Paragraph 47, Line 4",
                :paragraph_number=>"47",
                :submitted=>"word1 [word2] word3 word4 word5",
              }
            ]
          ],
          [
            %(
              Case: Leave text as is

              1. Page 7, Paragraph 47, Line 4
              Reads: word1 word2 word3 word4 word5
              Submitted: word1 [word2] word3 word4 word5
              ASREADS
            ),
            [
              {
                :before=>"word1 word2 word3 word4 word5",
                :correction_number=>"1",
                :first_line=>"1. Page 7, Paragraph 47, Line 4",
                :no_change=>true,
                :paragraph_number=>"47",
                :submitted=>"word1 [word2] word3 word4 word5",
              }
            ]
          ],
          [
            %(
              Case: Translator notes

              1. Page 7, Paragraph 47, Line 4
              Reads: word1 word2 word3 word4 word5
              Becomes: word1 (word2) word3 word4 word5
              TRN: This is a translator note.

            ),
            [
              {
                :after=>"word1 (word2) word3 word4 word5",
                :before=>"word1 word2 word3 word4 word5",
                :correction_number=>"1",
                :first_line=>"1. Page 7, Paragraph 47, Line 4",
                :paragraph_number=>"47",
                :translator_note=>"This is a translator note."
              }
            ]
          ],
          [
            %(
              Case: Editor notes

              1. Page 7, Paragraph 47, Line 4
              Reads: word1 word2 word3 word4 word5
              Becomes: word1 (word2) word3 word4 word5
              NCH: This is an editor note.

            ),
            [
              {
                :after=>"word1 (word2) word3 word4 word5",
                :before=>"word1 word2 word3 word4 word5",
                :correction_number=>"1",
                :first_line=>"1. Page 7, Paragraph 47, Line 4",
                :paragraph_number=>"47",
                :nch_note=>"This is an editor note."
              }
            ]
          ],
          [
            %(
              Case: Multi line content

              1. Page 7, Paragraph 47, Line 4
              Reads: para1 word1 word2 word3 word4 word5
              {: .normal}

              para2 word1 word2 word3
              {: .normal}
              Becomes: para1 word1 (word2) word3 word4 word5
              {: .normal}

              para2 word1 word2 word3
              {: .normal}
            ),
            [
              {
                :after=>"para1 word1 (word2) word3 word4 word5\n{: .normal}\n\npara2 word1 word2 word3\n{: .normal}",
                :before=>"para1 word1 word2 word3 word4 word5\n{: .normal}\n\npara2 word1 word2 word3\n{: .normal}",
                :correction_number=>"1",
                :first_line=>"1. Page 7, Paragraph 47, Line 4",
                :paragraph_number=>"47",
              }
            ]
          ],
          [
            %(
              Case: Different order

              1. Page 7, Paragraph 47, Line 4
              TRN: A translator note.
              Becomes: word1 (word2) word3 word4 word5
              NCH: An editor note.
              Reads: word1 word2 word3 word4 word5
            ),
            [
              {
                :after=>"word1 (word2) word3 word4 word5",
                :before=>"word1 word2 word3 word4 word5",
                :correction_number=>"1",
                :first_line=>"1. Page 7, Paragraph 47, Line 4",
                :paragraph_number=>"47",
                :nch_note=>"An editor note.",
                :translator_note=>"A translator note."
              }
            ]
          ],
        ].each do |(test_string, xpect)|
          it "extracts correct attrs" do
            AcceptedCorrectionsIntoContentAt.extract_corrections(
              test_string.gsub('              ', '') # remove leading spaces
            ).must_equal(xpect)
          end
        end
      end

      describe 'extract_relevant_paragraphs' do
        [
          [
            "# Header\n\nFirst paragraph without a number\n\n*2*{: .pn} second paragraph\n\n*3*{: .pn} third paragraph \n\n",
            { paragraph_number: '2', after: 'some text without any pararaph numbers so that only one para is relevant' },
            "\n*2*{: .pn} second paragraph\n"
          ],
          [
            "# Header\n\nFirst paragraph without a number\n\n*2*{: .pn} second paragraph\n\n*3*{: .pn} third paragraph \n\n",
            { paragraph_number: '2', after: "some text\n\n*2*{: .pn} with one pararaph number" },
            "\n*2*{: .pn} second paragraph\n\n*3*{: .pn} third paragraph "
          ],
          [
            "# Header\n\nFirst paragraph without a number\n\n*2*{: .pn} second paragraph\n\n*3*{: .pn} third paragraph\n\n*4*{: .pn} fourth paragraph",
            { paragraph_number: '2', after: "some text\n\n*2*{: .pn} with one pararaph number" },
            "\n*2*{: .pn} second paragraph\n\n*3*{: .pn} third paragraph\n"
          ],
          [
            "# Header\n\nFirst paragraph without a number\n\n@*2*{: .pn} second paragraph with subtitle_mark\n\n*3*{: .pn} third paragraph \n\n",
            { paragraph_number: '2', after: 'some text without any pararaph numbers so that only one para is relevant' },
            "\n@*2*{: .pn} second paragraph with subtitle_mark\n"
          ],
          [
            "# Header\n\nFirst paragraph without a number\n\n%*2*{: .pn} second paragraph with gap_mark\n\n*3*{: .pn} third paragraph \n\n",
            { paragraph_number: '2', after: 'some text without any pararaph numbers so that only one para is relevant' },
            "\n%*2*{: .pn} second paragraph with gap_mark\n"
          ],
          [
            "# Header\n\nFirst paragraph without a number\n\n@%*2*{: .pn} second paragraph with subtitle_mark and gap_mark\n\n*3*{: .pn} third paragraph \n\n",
            { paragraph_number: '2', after: 'some text without any pararaph numbers so that only one para is relevant' },
            "\n@%*2*{: .pn} second paragraph with subtitle_mark and gap_mark\n"
          ],
        ].each do |txt, correction, xpect|
          it "handles #{ txt.inspect }" do
            AcceptedCorrectionsIntoContentAt.send(
              :extract_relevant_paragraphs, txt, correction
            ).must_equal(xpect)
          end
        end
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
              before: 'second paragraph',
              after: 'second paragraph added',
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
              before: 'third paragraph',
              after: 'third paragraph added',
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

      describe 'validate_accepted_corrections_file' do
        [
          ['valid file', false],
          ['valid file with straight double quote inside IAL ^^^ {: .rid #rid-65040039 kpn="003"}', false],
          ['invalid file with EN DASH: –', true],
          ['invalid file with straight double quote: "', true],
          ['invalid file with straight single quote: \'', true],
        ].each do |test_string, xpect_exception|
          it "handles #{ test_string.inspect }" do
            if xpect_exception
              lambda {
                AcceptedCorrectionsIntoContentAt.send(
                  :validate_accepted_corrections_file, test_string
                )
              }.must_raise AcceptedCorrectionsIntoContentAt::InvalidAcceptedCorrectionsFile
            else
              # Call method and expect it not to raise an exception
              AcceptedCorrectionsIntoContentAt.send(
                :validate_accepted_corrections_file, test_string
              )
              1.must_equal 1
            end
          end
        end
      end

      describe 'validate_corrections' do
        [
          [
            [
              {
                :after => 'value_a',
                :before => 'value_b',
                :correction_number => 'value',
                :first_line => 'value',
                :paragraph_number => 'value',
              }
            ],
            nil,
          ],

          [
            [
              {
                :before => 'value_b',
                :no_change => true,
                :correction_number => 'value',
                :first_line => 'value',
                :paragraph_number => 'value',
              }
            ],
            nil,
          ],

          [
            [
              {
                :after => 'va',
                :before => 'vb',
                :correction_number => '1',
                :first_line => 'value',
                :paragraph_number => 'v',
              }, {
                :after => 'va',
                :before => 'vb',
                :correction_number => '2',
                :first_line => 'value',
                :paragraph_number => 'v',
              },
            ],
            nil,
          ],

          [
            [{}],
            AcceptedCorrectionsIntoContentAt::InvalidCorrectionAttributes,
          ],

          [
            [
              {
                :after => 'va',
                :before => 'vb',
                :correction_number => '1',
                :first_line => 'value',
                :paragraph_number => 'v',
              }, {
                :after => 'va',
                :before => 'vb',
                :correction_number => '3',
                :first_line => 'value',
                :paragraph_number => 'v',
              },
            ],
            AcceptedCorrectionsIntoContentAt::InvalidCorrectionNumber,
          ],

          [
            [
              {
                :after => 'identical',
                :before => 'identical',
                :correction_number => '1',
                :first_line => 'v',
                :paragraph_number => 'v',
              },
            ],
            AcceptedCorrectionsIntoContentAt::InvalidCorrectionAttributes,
          ],
        ].each do |corrections, xpected_exception|
          it "handles #{ corrections.inspect }" do
            if xpected_exception
              lambda {
                AcceptedCorrectionsIntoContentAt.send(
                  :validate_corrections, corrections
                )
              }.must_raise xpected_exception
            else
              # Call method and expect it not to raise an exception
              AcceptedCorrectionsIntoContentAt.send(
                :validate_corrections, corrections
              )
              1.must_equal 1
            end
          end
        end
      end

    end
  end
end


