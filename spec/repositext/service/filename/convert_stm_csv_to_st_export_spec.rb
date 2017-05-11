require_relative '../../../helper'

class Repositext
  class Service
    class Filename
      describe ConvertStmCsvToStExport do

        describe 'call' do
          [
            ['/path/eng65-0403_1234.subtitle_markers.csv', '/path/65-0403_1234.markers.txt'],
          ].each do |source_filename, xpect|
            it "handles #{ source_filename.inspect }" do
              ConvertStmCsvToStExport.call(
                source_filename: source_filename
              )[:result].must_equal(xpect)
            end
          end
        end

      end
    end
  end
end
