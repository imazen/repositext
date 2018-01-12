require_relative '../../../helper'

class Repositext
  class Validation
    class Validator

      describe SubtitleMarkSyntax do

        let(:default_subtitle){
          Subtitle.new({})
        }

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
              nil,
              [],
            ],
            [
              'Subtitle mark inside IAL 1',
              "word *word*{@: .smcaps} word",
              nil,
              [["Subtitle mark inside IAL", {:line =>1}, "word *word*{@: .smcaps} word"]]
            ],
            [
              'Subtitle mark inside IAL 2',
              "word *word*{: .sm@caps} word",
              nil,
              [["Subtitle mark inside IAL", {:line =>1}, "word *word*{: .sm@caps} word"]]
            ],
            [
              'Subtitle mark inside IAL 3',
              "word *word*{: .smcaps@} word",
              nil,
              [["Subtitle mark inside IAL", {:line =>1}, "word *word*{: .smcaps@} word"]]
            ],
            [
              'Subtitle mark inside IAL 4',
              "word word\n{: .@normal}\n\nword",
              nil,
              [["Subtitle mark inside IAL", {:line =>1}, "word word\n{: .@normal}"]]
            ],
            [
              'Subtitle mark inside opening parens',
              "word (@word word) word",
              nil,
              [["Subtitle mark on wrong side of parens", {:line =>1}, "word (@word word) word"]]
            ],
            [
              'Subtitle mark inside closing parens',
              "word (word word@) word",
              nil,
              [["Subtitle mark on wrong side of parens", {:line =>1}, "word (word word@) word"]]
            ],
            [
              'Subtitle mark inside a paragraph number',
              "*12@3*{: .pn} word word",
              nil,
              [["Subtitle mark inside paragraph number", {:line =>1}, "*12@3*{: .pn} word word"]]
            ],
            [
              'Subtitle mark at record boundary inside an editors note',
              "word [word @word] word",
              [Subtitle.new(tmp_attrs:{is_record_boundary: true})],
              [["Subtitle mark at record boundary inside editors note", {:line =>1}, "[word @word]"]]
            ]
          ].each do |description, test_string, test_subtitles, xpect|
            it "handles #{ description }" do
              r_file = get_r_file(contents: test_string)
              test_subtitles ||= Array.new(test_string.count('@'), default_subtitle)
              v = SubtitleMarkSyntax.new(r_file, '_', '_', { })
              v.send(
                :find_invalid_subtitle_marks,
                test_string,
                test_subtitles
              ).must_equal(xpect)
            end
          end
        end

      end

    end
  end
end
