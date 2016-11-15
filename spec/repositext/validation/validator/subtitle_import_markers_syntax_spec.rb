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
              v = SubtitleImportMarkersSyntax.new(
                FileLikeStringIO.new('/_', '_'),
                '_',
                '_',
                {}
              )
              if xpect
                v.send(
                  :no_unexpected_spaces?,
                  test_string
                )
                1.must_equal(1)
              else
                lambda {
                  v.send(
                    :no_unexpected_spaces?,
                    test_string
                  )
                }.must_raise(SubtitleImportMarkersSyntax::UnexpectedSpaceError)
              end
            end
          end

        end

      end

    end
  end
end
