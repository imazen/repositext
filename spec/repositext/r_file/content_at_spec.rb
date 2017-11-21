require_relative '../../helper'

class Repositext
  class RFile
    describe ContentAt do
      let(:default_rfile) { get_r_file(content_type: true) }
      let(:cab_rfile) {
        get_r_file(
          content_type: true,
          filename: '/path-to/rt-english/ct-general/content/chapters/engcab_01_-_title_1234.at'
        )
      }

      describe '#compute_similarity_with_corresponding_primary_file' do
        # TODO
      end

      describe '#corresponding_docx_export_filename' do
        it 'handles the default case' do
          default_rfile.corresponding_docx_export_filename.must_equal(
            '/path-to/rt-english/ct-general/docx_export/57/eng57-0103_1234.docx'
          )
        end
        it 'handles cab r_file' do
          cab_rfile.corresponding_docx_export_filename.must_equal(
            '/path-to/rt-english/ct-general/docx_export/chapters/engcab_01_-_title_1234.docx'
          )
        end
      end

      describe '#corresponding_docx_import_filename' do
        it 'handles the default case' do
          default_rfile.corresponding_docx_import_filename.must_equal(
            '/path-to/rt-english/ct-general/docx_import/57/eng57-0103_1234.docx'
          )
        end
        it 'handles cab r_file' do
          cab_rfile.corresponding_docx_import_filename.must_equal(
            '/path-to/rt-english/ct-general/docx_import/chapters/engcab_01_-_title_1234.docx'
          )
        end
      end

      describe '#corresponding_gap_mark_tagging_import_filename' do
        it 'handles the default case' do
          default_rfile.corresponding_gap_mark_tagging_import_filename.must_equal(
            '/path-to/rt-english/ct-general/gap_mark_tagging/57/eng57-0103_1234.gap_mark_tagging.txt'
          )
        end
        it 'handles cab r_file' do
          cab_rfile.corresponding_gap_mark_tagging_import_filename.must_equal(
            '/path-to/rt-english/ct-general/gap_mark_tagging/chapters/engcab_01_-_title_1234.gap_mark_tagging.txt'
          )
        end
      end

      describe '#corresponding_st_autosplit_filename' do
        it 'handles the default case' do
          default_rfile.corresponding_st_autosplit_filename.must_equal(
            '/path-to/rt-english/ct-general/autosplit_subtitles/57/eng57-0103_1234.txt'
          )
        end
        it 'handles cab r_file' do
          cab_rfile.corresponding_st_autosplit_filename.must_equal(
            '/path-to/rt-english/ct-general/autosplit_subtitles/chapters/engcab_01_-_title_1234.txt'
          )
        end
      end

      describe '#corresponding_subtitle_export_en_txt_filename' do
        it 'handles the default case' do
          default_rfile.corresponding_subtitle_export_en_txt_filename.must_equal(
            '/path-to/rt-english/ct-general/subtitle_export/57/57-0103_1234.en.txt'
          )
        end
        it 'handles cab r_file' do
          cab_rfile.corresponding_subtitle_export_en_txt_filename.must_equal(
            '/path-to/rt-english/ct-general/subtitle_export/chapters/engcab_01_-_title_1234.en.txt'
          )
        end
      end

      describe '#corresponding_subtitle_import_markers_filename' do
        it 'handles the default case' do
          default_rfile.corresponding_subtitle_import_markers_filename.must_equal(
            '/path-to/rt-english/ct-general/subtitle_import/57/57-0103_1234.markers.txt'
          )
        end
        it 'handles cab r_file' do
          cab_rfile.corresponding_subtitle_import_markers_filename.must_equal(
            '/path-to/rt-english/ct-general/subtitle_import/chapters/engcab_01_-_title_1234.markers.txt'
          )
        end
      end

      describe '#corresponding_subtitle_import_txt_filename' do
        it 'handles the default case' do
          default_rfile.corresponding_subtitle_import_txt_filename.must_equal(
            '/path-to/rt-english/ct-general/subtitle_import/57/57-0103_1234.en.txt'
          )
        end
        it 'handles cab r_file' do
          cab_rfile.corresponding_subtitle_import_txt_filename.must_equal(
            '/path-to/rt-english/ct-general/subtitle_import/chapters/cab_01_-_title_1234.en.txt'
          )
        end
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
        it 'handles cab r_file' do
          cab_rfile.corresponding_subtitle_markers_csv_filename.must_equal(
            '/path-to/rt-english/ct-general/content/chapters/engcab_01_-_title_1234.subtitle_markers.csv'
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
