require_relative '../helper'

class Repositext

  describe RFile do

    let(:contents) { 'contents' }
    let(:language) { Language::English.new }
    let(:content_type_name) { 'general' }
    let(:repo_name) { 'rt-english' }
    let(:path_to_repo) {
      File.join(Repository::Test.repos_folder, repo_name, '')
    }
    let(:repo) {
      Repository::Test.create!(repo_name)
      Repository::Content.new(path_to_repo)
    }
    let(:path_to_content_type) {
      File.join(repo.base_dir, "ct-#{ content_type_name }", '')
    }
    let(:content_type) {
      ContentType.new(path_to_content_type)
    }
    let(:file_basename) {
      "eng57-0103-1234.txt"
    }
    let(:content_type_relative_path_segments) {
      "content/57"
    }
    let(:filename) {
      File.join(path_to_content_type, content_type_relative_path_segments, file_basename)
    }
    let(:default_rfile) {
      RFile.new(contents, language, filename, content_type)
    }

    describe '.relative_path_from_to' do
      [
        [
          '/path/to/rt-spanish/ct-general/content/15/',
          '/path/to/rt-english/ct-general/content/15/eng15-1231_1234.at',
          '../../../../rt-english/ct-general/content/15/eng15-1231_1234.at',
        ],
        [
          '/path/to/rt-spanish/ct-general/content/15/',
          '/path/to/rt-english/ct-general/content/15/eng15-1231_1234.subtitle_markers.csv',
          '../../../../rt-english/ct-general/content/15/eng15-1231_1234.subtitle_markers.csv',
        ],
      ].each do |source_path, target_path, xpect|
        it "handles #{ source_path.inspect }" do
          RFile.relative_path_from_to(
            source_path,
            target_path
          ).must_equal(xpect)
        end
      end
    end

    describe '.get_class_for_filename' do
      [
        [
          '/repositext/rt-english/ct-general/content/57/eng57-0103_1234.subtitle_markers.csv',
          RFile::SubtitleMarkersCsv
        ],
        [
          '/repositext/rt-english/ct-general/content/57/eng57-0103_1234.data.json',
          RFile::DataJson
        ],
        [
          '/repositext/rt-english/ct-general/docx_import/57/eng57-0103_1234.docx',
          RFile::Docx
        ],
        [
          '/repositext/rt-english/ct-general/pdf_export/57/eng57-0103_1234.translator.pdf',
          RFile::Pdf
        ],
        [
          '/repositext/rt-english/ct-general/content/57/eng57-0103_1234.at',
          RFile::ContentAt
        ],
        [
          '/repositext/rt-english/ct-general/html_export/57/eng57-0103_1234.html',
          RFile::Content
        ],
        [
          '/repositext/rt-english/ct-general/reports/some_report.txt',
          RFile::Text
        ],
      ].each do |filename, xpect|
        it "handles #{ filename.inspect }" do
          RFile.get_class_for_filename(filename).must_equal(xpect)
        end
      end
    end

    describe '#initialize' do
      it 'initializes contents' do
        default_rfile.contents.must_equal(contents)
      end

      it 'initializes language' do
        default_rfile.language.must_equal(language)
      end

      it 'initializes filename' do
        default_rfile.filename.must_equal(filename)
      end
    end

    describe '#basename' do
      it 'handles default data' do
        default_rfile.basename.must_equal(file_basename)
      end
    end

    describe '#dir' do
      it 'handles default data' do
        default_rfile.dir.must_equal(filename.sub("/#{ file_basename }", ''))
      end
    end

    describe '#is_binary' do
      it 'returns false' do
        default_rfile.is_binary.must_equal(false)
      end
    end

    describe '#lang_code_3' do
      it 'returns correct value' do
        default_rfile.lang_code_3.must_equal(:eng)
      end
    end

    describe '#repo_relative_path' do
      it 'returns path without repo root by default' do
        default_rfile.repo_relative_path.must_equal(
          'ct-general/content/57/eng57-0103-1234.txt'
        )
      end

      it 'returns path with repo root if passed true' do
        default_rfile.repo_relative_path(true).must_equal(
          'rt-english/ct-general/content/57/eng57-0103-1234.txt'
        )
      end
    end

  end
end
