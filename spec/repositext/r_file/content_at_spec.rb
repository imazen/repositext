require_relative '../../helper'

class Repositext
  class RFile
    describe ContentAt do
      let(:contents) { "# title\n\nparagraph 1" }
      let(:language) { Language::English.new }
      let(:filename) { '/path-to/rt-english/ct-general/content/57/eng57-0103_1234.at' }
      let(:path_to_repo) { Repository::Test.create!('rt-english').first }
      let(:content_type) { ContentType.new(File.join(path_to_repo, 'ct-general')) }
      let(:default_rfile) {
        RFile::ContentAt.new(contents, language, filename, content_type)
      }

      describe '#compute_similarity_with_corresponding_primary_file' do
        # TODO
      end

      describe '#corresponding_json_lucene_export_filename' do
        it 'handles the default case' do
          default_rfile.corresponding_json_lucene_export_filename.must_equal(
            '/path-to/rt-english/lucene_table_export/json_export/ct-general/57/eng57-0103_1234.json'
          )
        end
      end
      #                                 ct-general/content/63/eng-1234.at
      # lucene_table_export/json_export/ct-general        /63/eng-1234.json

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
          default_rfile.kramdown_doc.to_html.must_equal("<h1 id=\"title\">title</h1>\n\n<p>paragraph 1</p>\n")
        end
      end

      describe '#plain_text_contents' do
        it 'handles the default case' do
          default_rfile.plain_text_contents({}).must_equal("title\nparagraph 1")
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
