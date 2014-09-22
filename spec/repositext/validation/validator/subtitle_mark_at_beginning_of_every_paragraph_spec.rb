require_relative '../../../helper'

class Repositext
  class Validation
    class Validator

      describe SubtitleMarkAtBeginningOfEveryParagraph do

        describe 'subtitle_mark_at_beginning_of_every_paragraph?' do

          it 'exits early on files that contain no subtitle_marks' do
            v = Validator::SubtitleMarkAtBeginningOfEveryParagraph.new('_', '_', '_', { :content_type => :import })
            v.send(
              :subtitle_mark_at_beginning_of_every_paragraph?,
              'text without subtitle_mark'
            ).success.must_equal(true)
          end

          it "doesn't raise an exception when given :import as :content_type option" do
            v = Validator::SubtitleMarkAtBeginningOfEveryParagraph.new('_', '_', '_', { :content_type => :import })
            v.send(:subtitle_mark_at_beginning_of_every_paragraph?, ' ')
            1.must_equal(1)
          end

          it "doesn't raise an exception when given :content as :content_type option" do
            v = Validator::SubtitleMarkAtBeginningOfEveryParagraph.new('_', '_', '_', { :content_type => :import })
            v.send(:subtitle_mark_at_beginning_of_every_paragraph?, ' ')
            1.must_equal(1)
          end

          it "raises an exception when given no :content_type option" do
            v = Validator::SubtitleMarkAtBeginningOfEveryParagraph.new('_', '_', '_', {})
            lambda {
              v.send(:subtitle_mark_at_beginning_of_every_paragraph?, '@test')
            }.must_raise ArgumentError
          end

          it "raises an exception when given :content_type :import and invalid data" do
            v = Validator::SubtitleMarkAtBeginningOfEveryParagraph.new('_', '_', '_', { :content_type => :import })
            lambda {
              v.send(
                :subtitle_mark_at_beginning_of_every_paragraph?,
                "# header\n\n@para1\n\npara2 without subtitle-mark\n\n"
              )
            }.must_raise Validator::SubtitleMarkAtBeginningOfEveryParagraph::NoSubtitleMarkAtBeginningOfParagraphError
          end

        end

        describe 'check_import_file' do
          [
            ["\n\n@para1\n\n@para2", []],
            ["\n\n@para1\n\npara2 without subtitle-mark", ['para2 without subtitle-mark']],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              v = Validator::SubtitleMarkAtBeginningOfEveryParagraph.new('_', '_', '_', { })
              v.send(
                :check_import_file,
                test_string
              ).must_equal(xpect)
            end
          end
        end

        describe 'check_content_file' do
          [
            [%(\n\n@para1 *with other tokens*{: .italic}\n\n^^^ {: .rid #rid-64080029 kpn="002"}\n\n@para2), []],
            [%(\n\n@para1 *with other tokens*{: .italic}\n\n^^^ {: .rid #rid-64080029 kpn="002"}\n\npara2 without subtitle-mark), ['para2 without subtitle-mark']],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              v = Validator::SubtitleMarkAtBeginningOfEveryParagraph.new('_', '_', '_', { })
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
            ["\n\n@para1\n\npara2", ['para2']],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              v = Validator::SubtitleMarkAtBeginningOfEveryParagraph.new('_', '_', '_', { })
              v.send(
                :get_paragraphs_that_dont_start_with_subtitle_mark,
                test_string
              ).must_equal(xpect)
            end
          end
        end

        describe 'remove_all_text_content_before_first_subtitle_mark' do
          [
            ["# header\n\n@para1\n", "\n\n@para1\n"],
            ["# header\n\n@para1\n\n@para2", "\n\n@para1\n\n@para2"],
            ['_', ''],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              v = Validator::SubtitleMarkAtBeginningOfEveryParagraph.new('_', '_', '_', { })
              v.send(
                :remove_all_text_content_before_first_subtitle_mark,
                test_string
              ).must_equal(xpect)
            end
          end
        end

      end

    end
  end
end
