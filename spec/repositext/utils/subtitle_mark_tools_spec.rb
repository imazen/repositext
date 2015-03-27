require_relative '../../helper'

class Repositext
  class Utils
    describe SubtitleMarkTools do

      describe 'extract_body_text_with_subtitle_marks_only' do
        [
          [
            "# title\n\n@word1\n@word2\n@word3",
            " title\n\n@word1\n@word2\n@word3"
          ],
          [
            "@word1\n@word2\n@word3\ncontent of id_title, will be stripped\n{: .id_title1 }\nmore id content that will be stripped",
            "@word1\n@word2\n@word3\n"
          ],
          [
            "@word1\n@word2\n@word3\n*em*{: ial='stripped'}\n^^^ {: .rid #rid-63120029}\n",
            "@word1\n@word2\n@word3\nem\n\n"
          ],
          [
            "# title\n@word1\n@word2\n\n### @subtitle\n@word3\n",
            " title\n@word1\n@word2\n @subtitle\n@word3\n"
          ],
          [
            %(\n\n@para1 *with other tokens*{: .italic}\n\n^^^ {: .rid #rid-64080029 kpn="002"}\n\n@para2),
            "\n\n@para1 with other tokens\n\n\n\n@para2"
          ]
        ].each do |test_string, xpect|
          it "handles #{ test_string.inspect }" do
            SubtitleMarkTools.send(
              :extract_body_text_with_subtitle_marks_only, test_string
            ).must_equal(xpect)
          end
        end
      end

      describe 'extract_captions' do
        [
          [
            "@23456@89012@456@8",
            true,
            [
              {char_pos: 1, char_length: 5, line: 1, excerpt: "@23456"},
              {char_pos: 7, char_length: 5, line: 1, excerpt: "@89012"},
              {char_pos: 13, char_length: 3, line: 1, excerpt: "@456"},
              {char_pos: 17, char_length: 1, line: 1, excerpt: "@8"},
            ]
          ],
          [
            "",
            true,
            []
          ],
          [
            "@with unicode@123@456\n@123",
            true,
            [
              {char_pos: 1, char_length: 12, line: 1, excerpt: "@with unicode"},
              {char_pos: 14, char_length: 4, line: 1, excerpt: "@123"},
              {char_pos: 19, char_length: 3, line: 1, excerpt: "@456\n"},
              {char_pos: 24, char_length: 3, line: 2, excerpt: "@123"},
            ]
          ],
          [
            "@ with leading whitespace@with trailing whitespace @123",
            true,
            [
              {char_pos: 1, char_length: 23, line: 1, excerpt: "@ with leading whitespace"},
              {char_pos: 26, char_length: 24, line: 1, excerpt: "@with trailing whitespace "},
              {char_pos: 52, char_length: 3, line: 1, excerpt: "@123"},
            ]
          ],
          [
            "word\n\n@with multiple\nlines\n@another one",
            true,
            [
              {char_pos: 7, char_length: 19, line: 3, excerpt: "@with multiple\nlines\n"},
              {char_pos: 28, char_length: 11, line: 5, excerpt: "@another one"},
            ]
          ],
        ].each do |test_string, txt_is_already_cleaned_up, xpect|
          it "handles #{ test_string.inspect }" do
            SubtitleMarkTools.send(
              :extract_captions, test_string, txt_is_already_cleaned_up
            ).must_equal(xpect)
          end
        end
      end


    end
  end
end
