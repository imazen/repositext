require_relative '../../../helper'

class Repositext
  class Validation
    class Validator

      describe SubtitleMarkNoSignificantChanges do

        describe 'significant_changes?' do

          it 'expects a non-empty content_at' do
            content_at_file = get_r_file(contents: ' ')
            stm_csv_file = get_r_file(contents: 'subtitle_marker_csv', sub_class: 'SubtitleMarkersCsv')
            v = SubtitleMarkNoSignificantChanges.new(
              [content_at_file, stm_csv_file], '_', '_', {})
            lambda {
              v.send(:significant_changes?, content_at_file, stm_csv_file)
            }.must_raise ArgumentError
          end

          it 'expects a non-empty subtitle_marker_csv' do
            content_at_file = get_r_file
            stm_csv_file = get_r_file(contents: ' ', sub_class: 'SubtitleMarkersCsv')
            v = SubtitleMarkNoSignificantChanges.new([content_at_file, stm_csv_file], '_', '_', {})
            lambda {
              v.send(:significant_changes?, content_at_file, stm_csv_file)
            }.must_raise ArgumentError
          end

          it "skips content_at files that don't contain subtitle_marks" do
            content_at_file = get_r_file(contents: 'content_at without any subtitle_marks')
            stm_csv_file = get_r_file(contents: "col1\tcol2\col3\tcol4\n", sub_class: 'SubtitleMarkersCsv')
            v = SubtitleMarkNoSignificantChanges.new([content_at_file, stm_csv_file], '_', '_', {})
            v.send(
              :significant_changes?,
              content_at_file,
              stm_csv_file,
            ).success.must_equal(true)
          end

        end

        describe 'compute_subtitle_mark_change' do
          [
            [1, 1, nil], # no change
            [1, 2, :significant], # > +30%
            [24, 16, :significant], # < -30%
            [24, 17, :insignificant], # > -30%
            [24, 31, :insignificant], # < +30%
            [24, 32, :significant], # > +30%
            [25, 18, :significant], # < -25%
            [25, 19, :insignificant], # > -25%
            [25, 31, :insignificant], # < +25%
            [25, 32, :significant], # > +25%
            [60, 45, :significant], # < -25%
            [60, 46, :insignificant], # > -25%
            [60, 74, :insignificant], # < +25%
            [60, 75, :significant], # > +25%
            [61, 48, :significant], # < -20%
            [61, 49, :insignificant], # > -20%
            [61, 73, :insignificant], # < +20%
            [61, 74, :significant], # > +20%
            [120, 95, :significant], # < -20%
            [120, 97, :insignificant], # > -20%
            [120, 121, :insignificant], # < +20%. We ignore the fact that it is too long.
            [120, 120, nil], # no change
          ].each do |old_len, new_len, xpect|
            it "handles #{ [old_len, new_len] }" do
              v = SubtitleMarkNoSignificantChanges.new('_', '_', '_', {})
              r = v.send(
                :compute_subtitle_mark_change,
                old_len, new_len
              )
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
