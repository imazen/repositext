require_relative '../../../helper'

class Repositext
  class Validation
    class Validator

      describe SubtitleMarkAtBeginningOfEveryParagraph do

        describe 'subtitle_mark_at_beginning_of_every_paragraph?' do

          it 'exits early on files that contain no subtitle_marks' do
            r_file = get_r_file(contents: 'text without subtitle_mark')
            v = SubtitleMarkAtBeginningOfEveryParagraph.new('_', '_', '_', { :content_type => :import })
            v.send(
              :subtitle_mark_at_beginning_of_every_paragraph?,
              r_file
            ).success.must_equal(true)
          end

          it "doesn't raise an exception when given :import as :content_type option" do
            r_file = get_r_file(contents: ' ')
            v = SubtitleMarkAtBeginningOfEveryParagraph.new(r_file, '_', '_', { :content_type => :import })
            v.send(:subtitle_mark_at_beginning_of_every_paragraph?, r_file)
            1.must_equal(1)
          end

          it "doesn't raise an exception when given :content as :content_type option" do
            r_file = get_r_file(contents: ' ')
            v = SubtitleMarkAtBeginningOfEveryParagraph.new(r_file, '_', '_', { :content_type => :import })
            v.send(:subtitle_mark_at_beginning_of_every_paragraph?, r_file)
            1.must_equal(1)
          end

          it "raises an exception when given no :content_type option" do
            r_file = get_r_file(contents: '@test')
            v = SubtitleMarkAtBeginningOfEveryParagraph.new(r_file, '_', '_', {})
            lambda {
              v.send(:subtitle_mark_at_beginning_of_every_paragraph?, r_file)
            }.must_raise ArgumentError
          end

          it "raises an exception when given :content_type :import and invalid data" do
            r_file = get_r_file(contents: "# header\n\n@para1\n\npara2 without subtitle-mark\n\n")
            v = SubtitleMarkAtBeginningOfEveryParagraph.new(r_file, '_', '_', { :content_type => :import })
            lambda {
              v.send(:subtitle_mark_at_beginning_of_every_paragraph?, r_file)
            }.must_raise SubtitleMarkAtBeginningOfEveryParagraph::NoSubtitleMarkAtBeginningOfParagraphError
          end

        end

        describe 'check_import_file' do
          [
            ["\n\n@para1\n\n@para2", []],
            ["\n\n@para1\n\npara2 without subtitle-mark", [['line 5', 'para2 without subtitle-mark']]],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              v = SubtitleMarkAtBeginningOfEveryParagraph.new('_', '_', '_', { })
              v.send(
                :check_import_file,
                test_string
              ).must_equal(xpect)
            end
          end
        end

        describe 'check_content_file' do
          [
            [
              %(\n\n@para1 *with other tokens*{: .italic}\n\n^^^ {: .rid #rid-64080029 kpn="002"}\n\n@para2),
              []
            ],
            [
              %(\n\n@para1 *with other tokens*{: .italic}\n\n^^^ {: .rid #rid-64080029 kpn="002"}\n\npara2 without subtitle-mark),
              [['line 7', 'para2 without subtitle-mark']]
            ],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              v = SubtitleMarkAtBeginningOfEveryParagraph.new('_', '_', '_', { })
              v.send(
                :check_content_file,
                test_string
              ).must_equal(xpect)
            end
          end
        end

        describe 'get_paragraphs_that_dont_start_with_subtitle_mark' do
          [
            ["\n\n@para1\n\n@para2", []],
            ["\n\n@para1\n\npara2", [['line 5', 'para2']]],
            [
              "\n\n@para1\n\npa@ra2\n\npara3@\n\npara4", [
                ['line 5', 'pa@ra2'],
                ['line 7', 'para3@'],
                ['line 9', 'para4'],
              ]
            ],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              v = SubtitleMarkAtBeginningOfEveryParagraph.new('_', '_', '_', { })
              v.send(
                :get_paragraphs_that_dont_start_with_subtitle_mark,
                test_string
              ).must_equal(xpect)
            end
          end
        end

        describe 'remove_all_text_content_before_second_record_id' do
          [
            ["^^^\n\n# header\n\n^^^\n\n@para1\n", "\n\n\n\n\n\n@para1"],
            ["^^^\n\n# header\n\n^^^\n\n@para1\n\n@para2", "\n\n\n\n\n\n@para1\n\n@para2"],
            ['leaves text without two record_marks intact', 'leaves text without two record_marks intact'],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              v = SubtitleMarkAtBeginningOfEveryParagraph.new('_', '_', '_', { })
              v.send(
                :remove_all_text_content_before_second_record_id,
                test_string
              ).must_equal(xpect)
            end
          end
        end

        describe 'empty_header_lines' do
          [
            ["[|# Header text|]\n\n@ word word\n", "\n\n@ word word\n"],
            ["[|# Header text|]\n\n@ word word\n\n[|# Header text|]\n\n@ word word", "\n\n@ word word\n\n\n\n@ word word"],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              v = SubtitleMarkAtBeginningOfEveryParagraph.new('_', '_', '_', { })
              v.send(
                :empty_header_lines,
                test_string
              ).must_equal(xpect)
            end
          end
        end

      end

    end
  end
end
