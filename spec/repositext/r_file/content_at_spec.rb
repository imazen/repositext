require_relative '../../helper'

class Repositext
  class RFile
    describe ContentAt do
      let(:default_rfile) { get_r_file(content_type: true) }

      describe '#compute_similarity_with_corresponding_primary_file' do
        # TODO
      end

      describe '#corresponding_subtitle_markers_csv_file' do
        # TODO
      end

      describe '#corresponding_subtitle_markers_csv_filename' do
        it 'handles the default case' do
          default_rfile.corresponding_subtitle_markers_csv_filename.must_equal(
            '/path-to/rt-english/ct-general/content/57/eng57-0103_1234.subtitle_markers.csv'
          )
        end
      end

      describe '#has_subtitles?' do
        it 'handles the default case' do
          default_rfile.has_subtitles?.must_equal(false)
        end
      end

      describe '#kramdown_doc' do
        it 'handles the default case' do
          default_rfile.kramdown_doc.to_html.must_equal("<h1 id=\"title\">Title</h1>\n\n<p>Paragraph 1</p>\n")
        end
      end

      describe '#plain_text_contents' do
        it 'handles the default case' do
          default_rfile.plain_text_contents({}).must_equal("Title\n\nParagraph 1\n")
        end
      end

      describe '#subtitles' do
        it 'handles the default case' do
          default_rfile.subtitles.must_equal([])
        end
      end
    end
  end
end
