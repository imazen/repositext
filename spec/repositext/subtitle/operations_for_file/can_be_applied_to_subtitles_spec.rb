require_relative '../../../helper'

class Repositext
  class Subtitle
    class OperationsForFile
      describe CanBeAppliedToSubtitles do
        let(:contents) { "_" }
        let(:language) { Language::English.new }
        let(:filename) { '/content/57/eng57-0103_1234.at' }

        let(:default_content_at_file) {
          RFile::ContentAt.new(contents, language, filename)
        }

        let(:default_json) {
%({
  "file_path": null,
  "productIdentityId": "1234",
  "language": "eng",
  "operations": [
    {
      "operationId": "0-1",
      "operationType": "split",
      "afterStid": null,
      "affectedStids": [
        {
          "stid": "4329043",
          "before": "word1 word2 word3, word4 word5. word6 word7 word8. word9, word10 word11 word12. ",
          "after": "word1 word2 word3, word4 word5. "
        },
        {
          "stid": "1250739",
          "before": "",
          "after": "word6 word7 word8. "
        },
        {
          "stid": "7453629",
          "before": "",
          "after": "word9, word10 word11 word12. word13 word14 word15 word16. "
        }
      ]
    },
    {
      "operationId": "0-3",
      "operationType": "move_right",
      "afterStid": null,
      "affectedStids": [
        {
          "stid": "7453629",
          "before": "",
          "after": "word9, word10 word11 word12. word13 word14 word15 word16. "
        },
        {
          "stid": "6033772",
          "before": "word13 word14 word15 word16. word17 word18, word19 word20 word21 word22? ",
          "after": "word17 word18, word19 word20 word21 word22? "
        }
      ]
    },
    {
      "operationId": "2-4",
      "operationType": "merge",
      "afterStid": null,
      "affectedStids": [
        {
          "stid": "6303325",
          "before": "word1 word2 word3 word4 word5 word6, ",
          "after": "word1 word2 word3 word4 word5 word6, word7 word8 word9 word10 word11. "
        },
        {
          "stid": "4248106",
          "before": "word7 word8 word9 word10 word11. ",
          "after": ""
        }
      ]
    }
  ]
})
        }

        let(:default_st_ops_for_file) {
          OperationsForFile.from_json(default_content_at_file, default_json)
        }

        let(:split_op) { default_st_ops_for_file.operations[0] }
        let(:move_right_op) { default_st_ops_for_file.operations[1] }
        let(:merge_op) { default_st_ops_for_file.operations[2] }

        let(:existing_subtitles) {
          [
            { persistent_id: '1234567' },
            { persistent_id: '4329043' },
            { persistent_id: '6033772' },
            { persistent_id: '2345678' },
            { persistent_id: '6303325' },
            { persistent_id: '4248106' },
            { persistent_id: '3456789' },
            { persistent_id: '4567890' },
          ]
        }

        describe '#apply_to_subtitles' do
          it 'handles default case' do
            default_st_ops_for_file.apply_to_subtitles(existing_subtitles).must_equal(
              [
                {:persistent_id=>"1234567"},
                {:persistent_id=>"4329043"},
                {:persistent_id=>"1250739"}, # inserted
                {:persistent_id=>"7453629"}, # inserted
                {:persistent_id=>"6033772"},
                {:persistent_id=>"2345678"},
                {:persistent_id=>"6303325"},
                                             # removed '4248106'
                {:persistent_id=>"3456789"},
                {:persistent_id=>"4567890"},
              ]
            )
          end
        end

        describe '#insert_new_subtitles!' do
          it 'handles default case' do
            default_st_ops_for_file.insert_new_subtitles!(existing_subtitles)
            existing_subtitles.must_equal(
              [
                {:persistent_id=>"1234567"},
                {:persistent_id=>"4329043"},
                {:persistent_id=>"1250739"}, # inserted
                {:persistent_id=>"7453629"}, # inserted
                {:persistent_id=>"6033772"},
                {:persistent_id=>"2345678"},
                {:persistent_id=>"6303325"},
                {:persistent_id=>"4248106"},
                {:persistent_id=>"3456789"},
                {:persistent_id=>"4567890"},
              ]
            )
          end
        end

        describe '#delete_subtitles!' do
          it 'handles default case' do
            default_st_ops_for_file.delete_subtitles!(existing_subtitles)
            existing_subtitles.must_equal(
              [
                {:persistent_id=>"1234567"},
                {:persistent_id=>"4329043"},
                {:persistent_id=>"6033772"},
                {:persistent_id=>"2345678"},
                {:persistent_id=>"6303325"},
                                             # removed '4248106'
                {:persistent_id=>"3456789"},
                {:persistent_id=>"4567890"},
              ]
            )
          end
        end

        describe '#compute_insert_at_index' do
          it 'handles default split_op' do
            default_st_ops_for_file.compute_insert_at_index(
              split_op,
              existing_subtitles
            ).must_equal(2)
          end
        end

        describe '#compute_insert_at_index_given_after_stid' do
          [
            ['new_file', 'new_file', 0],
            ['first stid', '1234567', 1],
            ['last stid', '4567890', -1],
          ].each do |desc, after_stid, xpect|
            it "handles #{ desc }" do
              default_st_ops_for_file.compute_insert_at_index_given_after_stid(
                after_stid, existing_subtitles
              ).must_equal(xpect)
            end
          end
        end

      end
    end
  end
end
