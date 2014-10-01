require_relative '../../helper'

class Repositext
  class Merge
    describe RecordMarksFromFolioXmlAtIntoIdmlAt do

      describe 'test cases' do

        base_path = get_test_data_path_for('repositext/merge/record_marks_from_folio_xml_at_into_idml_at')
        Dir.glob("#{ base_path }/file*.folio.at").each do |folio_test_file_path|

          it "handles #{ folio_test_file_path.gsub(base_path, '')}" do
            idml_test_file_path = folio_test_file_path.gsub('.folio.at', '.idml.at')
            xpect_test_file_path = folio_test_file_path.gsub('.folio.at', '.at')
            at_folio = File.read(folio_test_file_path)
            at_idml = File.read(idml_test_file_path)
            at_xpect = File.read(xpect_test_file_path)

            at_with_merged_tokens = RecordMarksFromFolioXmlAtIntoIdmlAt.merge(
              at_folio, at_idml
            )

            #at_with_merged_tokens.must_equal at_xpect
          end

        end
      end

    end
  end
end
