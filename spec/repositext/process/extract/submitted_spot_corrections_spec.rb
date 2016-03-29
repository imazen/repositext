require_relative '../../../helper'

class Repositext
  class Process
    class Extract
      describe SubmittedSpotCorrections do

        describe 'extract' do

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
                  :becomes=>"word1 (word2) word3 word4 word5",
                  :reads=>"word1 word2 word3 word4 word5",
                  :correction_number=>"1",
                  :first_line=>"1. Page 7, Paragraph 47, Line 4",
                  :paragraph_number=>"47"
                }, {
                  :becomes=>"word1 word2modified word3",
                  :reads=>"word1 word2 word3",
                  :correction_number=>"2",
                  :first_line=>"2. Page 8, Paragraphs 54-57, Line 7",
                  :paragraph_number=>"54"
                }, {
                  :becomes=>"word1 word2 word4added word3",
                  :reads=>"word1 word2 word3",
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
                  :becomes=>"word1 (word2) word3 word4 word5",
                  :reads=>"word1 word2 word3 word4 word5",
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
                  :reads=>"word1 word2 word3 word4 word5",
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
                  :becomes=>"word1 (word2) word3 word4 word5",
                  :reads=>"word1 word2 word3 word4 word5",
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
                  :becomes=>"word1 (word2) word3 word4 word5",
                  :reads=>"word1 word2 word3 word4 word5",
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
                  :becomes=>"para1 word1 (word2) word3 word4 word5\n{: .normal}\n\npara2 word1 word2 word3\n{: .normal}",
                  :reads=>"para1 word1 word2 word3 word4 word5\n{: .normal}\n\npara2 word1 word2 word3\n{: .normal}",
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
                  :becomes=>"word1 (word2) word3 word4 word5",
                  :reads=>"word1 word2 word3 word4 word5",
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
              SubmittedSpotCorrections.extract(
                test_string.gsub('                ', '') # remove leading spaces
              ).must_equal(xpect)
            end
          end
        end

      end
    end
  end
end

