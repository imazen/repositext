require_relative '../../helper'

class Repositext
  class Utils
    describe CorrespondingPrimaryFileFinder do

      describe '.find' do
        [
          [
            {
              filename: '/path/to/foreign_repo/more/path/to/spn-file.txt',
              language_code_3_chars: 'spn',
              content_type_dir: '/path/to/foreign_repo/',
              relative_path_to_primary_content_type: '../primary_repo/content_type',
              primary_repo_lang_code: 'eng',
            },
            '/path/to/primary_repo/content_type/more/path/to/eng-file.txt'
          ],
        ].each do |params, xpect|
          it "handles #{ params.inspect }" do
            CorrespondingPrimaryFileFinder.find(params).must_equal(xpect)
          end
        end
      end

    end
  end
end

