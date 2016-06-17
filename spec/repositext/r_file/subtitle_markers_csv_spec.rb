require_relative '../../helper'

class Repositext
  class RFile
    describe SubtitleMarkersCsv do
      let(:subtitle_attrs) { [
        ['relativeMS', 'samples', 'charLength', 'persistentId', 'recordId'],
        [ 0,            0,         81,          '7643098',      '63030019'],
        [ 5235,         230843,    51,          '2048512',      '63030019'],
        [ 6033,         496912,    64,          '1579036',      '63030019'],
        [ 4069,         676375,    77,          '9863465',      '63030019'],
        [ 6050,         943184,    58,          '7598234',      '63030029'],
        [ 5093,         1167788,   103,         '7497864',      '63030029'],
        [ 10303,        1622128,   72,          '4985777',      '63030029'],
      ] }
      let(:contents) {
        subtitle_attrs.map { |line_attrs|
          line_attrs.join("\t")
        }.join("\n") + "\n"
      }
      let(:language) { Repositext::Language::English.new }
      let(:filename) { '/content/57/eng0103-1234.subtitle_markers.csv' }
      let(:default_rfile) { RFile::SubtitleMarkersCsv.new(contents, language, filename) }

      describe '#subtitles' do
        it "handles default data" do
          default_rfile.subtitles.map { |subtitle|
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
