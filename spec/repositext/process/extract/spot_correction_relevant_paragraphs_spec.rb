require_relative '../../../helper'

class Repositext
  class Process
    class Extract
      describe SpotCorrectionRelevantParagraphs do

        describe 'extract' do

          [
            [
              "# Header\n\nFirst paragraph without a number\n\n*2*{: .pn} second paragraph\n\n*3*{: .pn} third paragraph \n\n",
              { paragraph_number: '2', becomes: 'some text without any pararaph numbers so that only one para is relevant' },
              ["\n*2*{: .pn} second paragraph\n", 5]
            ],
            [
              "# Header\n\n(This scenario uses the `submitted` key instead of `after`.\n\n*2*{: .pn} second paragraph\n\n*3*{: .pn} third paragraph \n\n",
              { paragraph_number: '2', submitted: 'some text without any pararaph numbers so that only one para is relevant' },
              ["\n*2*{: .pn} second paragraph\n", 5]
            ],
            [
              "# Header\n\nFirst paragraph without a number\n\n*2*{: .pn} second paragraph\n\n*3*{: .pn} third paragraph \n\n",
              { paragraph_number: '2', becomes: "some text\n\n*2*{: .pn} with one pararaph number" },
              ["\n*2*{: .pn} second paragraph\n\n*3*{: .pn} third paragraph ", 5]
            ],
            [
              "# Header\n\nFirst paragraph without a number\n\n*2*{: .pn} second paragraph\n\n*3*{: .pn} third paragraph\n\n*4*{: .pn} fourth paragraph",
              { paragraph_number: '2', becomes: "some text\n\n*2*{: .pn} with one pararaph number" },
              ["\n*2*{: .pn} second paragraph\n\n*3*{: .pn} third paragraph\n", 5]
            ],
            [
              "# Header\n\nFirst paragraph without a number\n\n@*2*{: .pn} second paragraph with subtitle_mark\n\n*3*{: .pn} third paragraph \n\n",
              { paragraph_number: '2', becomes: 'some text without any pararaph numbers so that only one para is relevant' },
              ["\n@*2*{: .pn} second paragraph with subtitle_mark\n", 5]
            ],
            [
              "# Header\n\nFirst paragraph without a number\n\n%*2*{: .pn} second paragraph with gap_mark\n\n*3*{: .pn} third paragraph \n\n",
              { paragraph_number: '2', becomes: 'some text without any pararaph numbers so that only one para is relevant' },
              ["\n%*2*{: .pn} second paragraph with gap_mark\n", 5]
            ],
            [
              "# Header\n\nFirst paragraph without a number\n\n@%*2*{: .pn} second paragraph with subtitle_mark and gap_mark\n\n*3*{: .pn} third paragraph \n\n",
              { paragraph_number: '2', becomes: 'some text without any pararaph numbers so that only one para is relevant' },
              ["\n@%*2*{: .pn} second paragraph with subtitle_mark and gap_mark\n", 5]
            ],
          ].each do |txt, correction, xpect|
            it "handles #{ txt.inspect }" do
              SpotCorrectionRelevantParagraphs.send(
                :extract, correction, txt
              ).must_equal({
                relevant_paragraphs: xpect.first,
                paragraph_start_line_number: xpect.last
              })
            end
          end
        end

        describe 'compute_first_para_num' do
          [
            ["*1*{: .pn} the first para\n\n*141*{: .pn}", '1'],
            ["*2*{: .pn} the first para\n\n*141*{: .pn}", '1'],
            ["@*3*{: .pn} the first para\n\n*141*{: .pn}", '2'],
            ["%*4*{: .pn} the first para\n\n*141*{: .pn}", '3'],
            ["@%*5*{: .pn} the first para\n\n*141*{: .pn}", '4'],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              SpotCorrectionRelevantParagraphs.send(
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
              SpotCorrectionRelevantParagraphs.send(
                :compute_last_para_num, test_string
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
              SpotCorrectionRelevantParagraphs.send(
                :compute_line_number_from_paragraph_number, paragraph_number, test_string
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
              SpotCorrectionRelevantParagraphs.send(
                :dynamic_paragraph_number_regex, paragraph_number, test_string
              ).must_equal(xpect)
            end
          end
        end


      end
    end
  end
end

