# encoding UTF-8
require_relative '../helper'

class Repositext

  describe Subtitle do

    # All attrs are given as string, same as coming from CSV file
    let(:default_attrs) { {
      char_length: '72',
      contents: 'subtitle contents',
      persistent_id: '3276590',
      record_id: '63030029',
      relative_milliseconds: '10303',
      samples: '1622128'
    } }
    let(:default_subtitle) { Subtitle.new(default_attrs) }

    describe '#initialize' do

      it 'initializes char_length to int' do
        default_subtitle.char_length.must_equal(72)
      end

      it 'initializes contents' do
        default_subtitle.contents.must_equal('subtitle contents')
      end

      it 'initializes persistent_id' do
        default_subtitle.persistent_id.must_equal('3276590')
      end

      it 'initializes record_id' do
        default_subtitle.record_id.must_equal('63030029')
      end

      it 'initializes relative_milliseconds to int' do
        default_subtitle.relative_milliseconds.must_equal(10303)
      end

      it 'initializes samples to int' do
        default_subtitle.samples.must_equal(1622128)
      end

    end

    it 'computes absolute_milliseconds from samples' do
      default_subtitle.absolute_milliseconds.must_equal(36783)
    end

    describe '.valid_stid_format?' do
      [
        ['1000000', true],
        ['4567890', true],
        ['9999999', true],
        ['0000001', false],
        ['10000', false],
        ['10000000', false],
      ].each do |(stid, xpect)|
        it "handles #{ stid.inspect }" do
          Subtitle.valid_stid_format?(stid).must_equal(xpect)
        end
      end
    end

  end

end
