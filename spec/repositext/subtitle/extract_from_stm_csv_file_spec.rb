require_relative '../../helper'

class Repositext
  class Subtitle
    describe ExtractFromStmCsvFile do

      let(:subtitle_attrs) { [
        ['relativeMS', 'samples', 'charLength', 'persistentId', 'recordId'],
        [ 0,            0,         81,          '5AXK',         '63030019'],
        [ 5235,         230843,    51,          'ZXrr',         '63030019'],
        [ 6033,         496912,    64,          'pxS9',         '63030019'],
        [ 4069,         676375,    77,          'PrHS',         '63030019'],
        [ 6050,         943184,    58,          'pBfs',         '63030029'],
        [ 5093,         1167788,   103,         'Euhn',         '63030029'],
        [ 10303,        1622128,   72,          'Qt56',         '63030029'],
      ] }
      let(:subtitle_markers_csv_file_contents) {
        subtitle_attrs.map { |line_attrs|
          line_attrs.join("\t")
        }.join("\n") + "\n"
      }
      let(:language) { Repositext::Language::English.new }
      let(:subtitle_markers_csv_file) {
        RFile.new(
          subtitle_markers_csv_file_contents,
          language,
          'filename'
        )
      }

      describe '#extract' do
        it "extracts subtitles" do
          r = ExtractFromStmCsvFile.new(subtitle_markers_csv_file).extract
          r.map { |subtitle|
            [
              subtitle.relative_milliseconds,
              subtitle.samples,
              subtitle.char_length,
              subtitle.persistent_id,
              subtitle.record_id,
            ]
          }.must_equal(subtitle_attrs[1..-1])
        end
      end

    end
  end
end
