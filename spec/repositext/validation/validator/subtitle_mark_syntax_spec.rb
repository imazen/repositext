require_relative '../../../helper'

class Repositext
  class Validation
    class Validator

      describe SubtitleMarkSyntax do

        describe 'subtitle_marks_valid?' do

          it 'exits early on files that contain no subtitle_marks' do
            r_file = get_r_file(contents: 'text without subtitle_mark')
            v = SubtitleMarkSyntax.new(r_file, '_', '_', {})
            v.send(
              :subtitle_marks_valid?,
              r_file
            ).success.must_equal(true)
          end

        end

        describe 'find_invalid_subtitle_marks' do
          [
            [
              "Valid subtitle marks",
              "@word word @@word",
              [],
            ],
            [
              'Subtitle mark inside IAL 1',
              "word *word*{@: .smcaps} word",
              [["Subtitle mark inside IAL:", 1, "word *word*{@: .smcaps} word"]]
            ],
            [
              'Subtitle mark inside IAL 2',
              "word *word*{: .sm@caps} word",
              [["Subtitle mark inside IAL:", 1, "word *word*{: .sm@caps} word"]]
            ],
            [
              'Subtitle mark inside IAL 3',
              "word *word*{: .smcaps@} word",
              [["Subtitle mark inside IAL:", 1, "word *word*{: .smcaps@} word"]]
            ],
            [
              'Subtitle mark inside IAL 4',
              "word word\n{: .@normal}\n\nword",
              [["Subtitle mark inside IAL:", 1, "word word\n{: .@normal}"]]
            ],
            [
              'Subtitle mark inside parenthesis 1',
              "word (@word word) word",
              [["Subtitle mark inside parenthesis:", 1, "word (@word word) word"]]
            ],
            [
              'Subtitle mark inside parenthesis 2',
              "word (word @word) word",
              [["Subtitle mark inside parenthesis:", 1, "word (word @word) word"]]
            ],
            [
              'Subtitle mark inside parenthesis 3',
              "word (word word@) word",
              [["Subtitle mark inside parenthesis:", 1, "word (word word@) word"]]
            ],
          ].each do |description, test_string, xpect|
            it "handles #{ description }" do
              r_file = get_r_file(contents: test_string)
              v = SubtitleMarkSyntax.new(r_file, '_', '_', { })
              v.send(
                :find_invalid_subtitle_marks,
                test_string
              ).must_equal(xpect)
            end
          end
        end

      end

    end
  end
end
