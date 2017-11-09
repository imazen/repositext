require_relative '../../../helper'

class Repositext
  class Validation
    class Validator

      describe SubtitleImportMarkersSyntax do

        describe '#no_unexpected_spaces?' do

          [
            ["markers\tcontent\twith\ttabs\tonly", true],
            ["markers content with spaces", false],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              st_import_markers_file = get_r_file(
                contents: test_string,
                sub_class: 'Csv'
              )
              v = SubtitleImportMarkersSyntax.new(
                st_import_markers_file,
                '_',
                '_',
                {}
              )
              if xpect
                v.send(:no_unexpected_spaces?, st_import_markers_file)
                1.must_equal(1)
              else
                lambda {
                  v.send(:no_unexpected_spaces?, st_import_markers_file)
                }.must_raise(SubtitleImportMarkersSyntax::UnexpectedSpaceError)
              end
            end
          end

        end

      end

    end
  end
end
