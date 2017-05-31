require_relative '../../helper'

class Repositext
  class Utils
    describe SubtitleFilenameConverter do

      describe '#convert_from_repositext_to_subtitle_export' do
        [
          [
            "/eng47-0412_0002.at",
            { extension: 'txt' },
            "/47-0412_0002.en.txt",
          ],
          [
            "/eng47-0412_0002.at",
            { extension: 'rt.txt' },
            "/47-0412_0002.en.rt.txt",
          ],
          [
            "/eng47-0412_0002.at",
            { extension: 'markers.txt' },
            "/47-0412_0002.markers.txt",
          ],
          [
            "/eng47-0412_0002.at",
            { extension: 'subtitle_markers.csv' },
            "/47-0412_0002.subtitle_markers.csv",
          ],
          [
            "/engcab_05_-_title_1234.at",
            { extension: 'txt' },
            "/cab_05_-_title_1234.en.txt",
          ],
          [
            "/engcab_05_-_title_1234.at",
            { extension: 'markers.txt' },
            "/cab_05_-_title_1234.markers.txt",
          ],
          [
            "/engcab_05_-_title_1234.at",
            { extension: 'subtitle_markers.csv' },
            "/cab_05_-_title_1234.subtitle_markers.csv",
          ],
        ].each do |(rt_filename, output_file_attrs, xpect)|
          it "handles #{ rt_filename.inspect }" do
            SubtitleFilenameConverter.send(
              :convert_from_repositext_to_subtitle_export,
              rt_filename,
              output_file_attrs
            ).must_equal(xpect)
          end
        end
      end

      describe '#convert_from_repositext_to_subtitle_import' do
        [
          [
            "/eng47-0412_0002.at",
            "/47-0412_0002.en.txt",
          ],
          [
            "/engcab_05_-_title_1234.at",
            "/cab_05_-_title_1234.en.txt",
          ],
        ].each do |(rt_filename, xpect)|
          it "handles #{ rt_filename.inspect }" do
            SubtitleFilenameConverter.send(
              :convert_from_repositext_to_subtitle_import,
              rt_filename,
            ).must_equal(xpect)
          end
        end
      end

      describe '#convert_from_subtitle_import_to_repositext' do
        [
          [
            "/47/47-0412_0002.en.txt",
            "/47/eng47-0412_0002.at",
          ],
          [
            "/cab_05_-_title_1234.en.txt",
            "/engcab_05_-_title_1234.at",
          ],
        ].each do |(st_filename, xpect)|
          it "handles #{ st_filename.inspect }" do
            SubtitleFilenameConverter.send(
              :convert_from_subtitle_import_to_repositext,
              st_filename,
            ).must_equal(xpect)
          end
        end
      end

    end
  end
end
