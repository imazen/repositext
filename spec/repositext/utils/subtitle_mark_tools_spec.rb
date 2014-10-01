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
            "@word1\n@word2\n@word3\nem"
          ],
          [
            "# title\n@word1\n@word2\n\n### @subtitle\n@word3\n",
            " title\n@word1\n@word2\n @subtitle\n@word3\n"
          ],
          [
            %(\n\n@para1 *with other tokens*{: .italic}\n\n^^^ {: .rid #rid-64080029 kpn="002"}\n\n@para2),
            "\n\n@para1 with other tokens\n\n@para2"
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
              {:char_pos=>1, :char_length=>5, :excerpt=>"@23456"},
              {:char_pos=>7, :char_length=>5, :excerpt=>"@89012"},
              {:char_pos=>13, :char_length=>3, :excerpt=>"@456"},
              {:char_pos=>17, :char_length=>1, :excerpt=>"@8"},
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
              {:char_pos=>1, :char_length=>12, :excerpt=>"@with unicode"},
              {:char_pos=>14, :char_length=>4, :excerpt=>"@123"},
              {:char_pos=>19, :char_length=>3, :excerpt=>"@456\n"},
              {:char_pos=>24, :char_length=>3, :excerpt=>"@123"},
            ]
          ],
          [
            "@ with leading whitespace@with trailing whitespace @123",
            true,
            [
              {:char_pos=>1, :char_length=>23, :excerpt=>"@ with leading whitespace"},
              {:char_pos=>26, :char_length=>24, :excerpt=>"@with trailing whitespace "},
              {:char_pos=>52, :char_length=>3, :excerpt=>"@123"},
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
