require_relative '../../../helper'

class Repositext
  class Process
    class Fix
      describe MoveSubtitleMarksToNearbySentenceBoundaries do

        let(:language) { Language::English.new }
        let(:text) { Text.new('word-3 word-2 @word word+1 word+1', language) }
        let(:fixer){ MoveSubtitleMarksToNearbySentenceBoundaries.new(text) }

        # def initialize(text)
        #   @contents = text.contents
        #   @language = text.language

        # def fix
        describe '#fix' do

          [
            [
              'No sentence boundary, leave as is',
              'word word word word-3 word-2 word-1 @word-0 word+1 word+2',
              'word word word word-3 word-2 word-1 @word-0 word+1 word+2',
            ],
            [
              'Sentence boundary nearby, move single subtitle_mark',
              'word word word word-3. word-2 word-1 @word-0 word+1 word+2',
              'word word word word-3. @word-2 word-1 word-0 word+1 word+2',
            ],
            [
              'Sentence boundary too far away, leave as is',
              'word word word. word-3 word-2 word-1 @word-0 word+1 word+2',
              'word word word. word-3 word-2 word-1 @word-0 word+1 word+2'
            ],
            [
              'Single subtitle mark between sentence boundaries, move to closest',
              'word-3. word-2 word-1 @word-0. word+1 word+2',
              'word-3. word-2 word-1 word-0. @word+1 word+2'
            ],
            [
              'Single subtitle mark between equidistant sentence boundaries, move to previous',
              'word-3. word-2 word-1 @word-0 word+1. word+2',
              'word-3. @word-2 word-1 word-0 word+1. word+2'
            ],
            [
              'Multiple subtitle marks with non-overlapping surroundings, move to closest sentence boundaries',
              'word word-3. word-2 word-1 @word-0 word+1 word+2 word word-3 word-2 word-1 @word-0 word+1. word+2',
              'word word-3. @word-2 word-1 word-0 word+1 word+2 word word-3 word-2 word-1 word-0 word+1. @word+2'
            ],
            [
              'Multiple subtitle marks with overlapping surroundings, move only first stm',
              'word word-3. word-2 word-1 @word-0 word+1 word+2 @word+2-0 word+1. word+2',
              'word word-3. @word-2 word-1 word-0 word+1 word+2 @word+2-0 word+1. word+2'
            ],
          ].each do |description, tst, xpect|
            it "handles #{ description }" do
              l_text = Text.new(tst, language)
              l_fixer = MoveSubtitleMarksToNearbySentenceBoundaries.new(l_text)
              l_fixer.fix.result.must_equal(xpect)
            end
          end

        end

        describe '#idle_state_handler!' do

          [
            [ 'word word word word-3 word-2 word-1 @word-0 word+1 word+2',  'word word word '],
            [ 'word word word word word',  'word word word word word'],
          ].each do |tst, xpect|
            it "handles #{ tst.inspect }" do
              r = ''
              ss = StringScanner.new(tst)
              fixer.send(:idle_state_handler!, ss, r)
              r.must_equal(xpect)
            end
          end

        end

        describe '#move_after_closest_sentence_boundary_state_handler!' do

          [
            [ 'word-3 word-2 word-1 @word-0 word+1 word+2',  'word-3 word-2 word-1 @word-0 word+1 word+2'],
            ['word-3. word-2 word-1 @word-0 word+1 word+2', 'word-3. @word-2 word-1 word-0 word+1 word+2'],
            ['word-3 word-2. word-1 @word-0 word+1 word+2', 'word-3 word-2. @word-1 word-0 word+1 word+2'],
            ['word-3 word-2 word-1. @word-0 word+1 word+2', 'word-3 word-2 word-1. @word-0 word+1 word+2'],
            ['word-3 word-2 word-1 @word-0. word+1 word+2', 'word-3 word-2 word-1 word-0. @word+1 word+2'],
            ['word-3 word-2 word-1 @word-0 word+1. word+2', 'word-3 word-2 word-1 word-0 word+1. @word+2'],
            [       'word-2 word-1 @word-0 word+1. word+2',        'word-2 word-1 word-0 word+1. @word+2'],
            [              'word-1 @word-0 word+1. word+2',               'word-1 word-0 word+1. @word+2'],
            [                     '@word-0 word+1. word+2', ''], # won't touch stm at beginning of line
            [ '@word-0. word+1 word+2', ''], # won't move stm at beginning of line
          ].each do |tst, xpect|
            it "handles #{ tst.inspect }" do
              r = ''
              ss = StringScanner.new(tst)
              fixer.send(:move_after_closest_sentence_boundary_state_handler!, ss, r)
              r.must_equal(xpect)
            end
          end

        end

        describe '#extract_subtitle_mark_and_surroundings!' do

          [
            ['word-3 word-2 word-1 @word-0 word+1 word+2', ['word-3', 'word-2', 'word-1', '@word-0', 'word+1', 'word+2']],
            [       'word-2 word-1 @word-0 word+1 word+2', [nil,      'word-2', 'word-1', '@word-0', 'word+1', 'word+2']],
            [              'word-1 @word-0 word+1 word+2', [nil,      nil,      'word-1', '@word-0', 'word+1', 'word+2']],
            [                     '@word-0 word+1 word+2', [nil,      nil,      nil,      nil,       nil,      nil]], # won't extract stm at beginning of line
            ['word-3 word-2 word-1 @word-0',               ['word-3', 'word-2', 'word-1', '@word-0', nil,      nil]],
            [       'word-2 word-1 @word-0',               [nil,      'word-2', 'word-1', '@word-0', nil,      nil]],
            [              'word-1 @word-0',               [nil,      nil,      'word-1', '@word-0', nil,      nil]],
            [                     '@word-0',               [nil,      nil,      nil,      nil,       nil,      nil]], # won't extract stm at beginning of line
          ].each do |tst, xpect|
            it "handles #{ tst.inspect }" do
              ss = StringScanner.new(tst)
              fixer.send(:extract_subtitle_mark_and_surroundings!, ss).must_equal(xpect)
            end
          end

        end

        describe '#compute_index_of_closest_sentence_boundary' do

          [
            [['word-3', 'word-2', 'word-1', '@word-0', 'word+1', 'word+2'], nil],
            [['word-3.','word-2', 'word-1', '@word-0', 'word+1', 'word+2'], 0],
            [['word-3', 'word-2.','word-1', '@word-0', 'word+1', 'word+2'], 1],
            [['word-3', 'word-2', 'word-1.','@word-0', 'word+1', 'word+2'], 2],
            [['word-3', 'word-2', 'word-1', '@word-0.','word+1', 'word+2'], 3],
            [['word-3', 'word-2', 'word-1', '@word-0', 'word+1.','word+2'], 4],
            [[nil,      'word-2', 'word-1', '@word-0', 'word+1.','word+2'], 4],
            [[nil,      nil,      'word-1', '@word-0', 'word+1.','word+2'], 4],
            [['word-3.','word-2', 'word-1', '@word-0', nil,      nil],      0],
            [['word-3.','word-2', 'word-1', nil,       nil,      nil],      0],
            [[nil,      nil,      'word-1', nil,       nil,      nil],      nil],
          ].each do |tst, xpect|
            it "handles #{ tst.inspect }" do
              r = fixer.send(:compute_index_of_closest_sentence_boundary, tst)
              if xpect.nil?
                r.must_be(:nil?)
              else
                r.must_equal(xpect)
              end
            end
          end

        end

      end
    end
  end
end
