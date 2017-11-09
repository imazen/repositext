require_relative '../../../helper'

class Repositext
  class Subtitle
    class OperationsForFile
      describe CanBeAppliedToSubtitles do
        let(:default_content_at_file) {
          f = get_r_file
          f.do_not_load_contents_from_disk_for_testing = true
          f
        }

        let(:default_json) {
%({
  "file_path": null,
  "from_git_commit": "1234",
  "to_git_commit": "2345",
  "product_identity_id": "1234",
  "language": "eng",
  "operations": [
    {
      "operation_id": "0-1",
      "operation_type": "split",
      "after_stid": null,
      "affected_stids": [
        {
          "stid": "4329043",
          "record_id": null,
          "before": "word1 word2 word3, word4 word5. word6 word7 word8. word9, word10 word11 word12. ",
          "after": "word1 word2 word3, word4 word5. "
        },
        {
          "stid": "1250739",
          "record_id": null,
          "before": "",
          "after": "word6 word7 word8. "
        },
        {
          "stid": "7453629",
          "record_id": null,
          "before": "",
          "after": "word9, word10 word11 word12. word13 word14 word15 word16. "
        }
      ]
    },
    {
      "operation_id": "0-3",
      "operation_type": "move_right",
      "after_stid": null,
      "affected_stids": [
        {
          "stid": "7453629",
          "record_id": null,
          "before": "",
          "after": "word9, word10 word11 word12. word13 word14 word15 word16. "
        },
        {
          "stid": "6033772",
          "record_id": null,
          "before": "word13 word14 word15 word16. word17 word18, word19 word20 word21 word22? ",
          "after": "word17 word18, word19 word20 word21 word22? "
        }
      ]
    },
    {
      "operation_id": "2-4",
      "operation_type": "merge",
      "after_stid": null,
      "affected_stids": [
        {
          "stid": "6303325",
          "record_id": null,
          "before": "word1 word2 word3 word4 word5 word6, ",
          "after": "word1 word2 word3 word4 word5 word6, word7 word8 word9 word10 word11. "
        },
        {
          "stid": "4248106",
          "record_id": null,
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
            { persistent_id: '1234567', record_id: nil },
            { persistent_id: '4329043', record_id: nil },
            { persistent_id: '6033772', record_id: nil },
            { persistent_id: '2345678', record_id: nil },
            { persistent_id: '6303325', record_id: nil },
            { persistent_id: '4248106', record_id: nil },
            { persistent_id: '3456789', record_id: nil },
            { persistent_id: '4567890', record_id: nil },
          ]
        }

        describe '#apply_to_subtitles' do
          it 'handles default case' do
            default_st_ops_for_file.apply_to_subtitles(existing_subtitles).must_equal(
              [
                {:persistent_id=>"1234567", record_id: nil},
                {:persistent_id=>"4329043", record_id: nil},
                {:persistent_id=>"1250739", record_id: nil}, # inserted
                {:persistent_id=>"7453629", record_id: nil}, # inserted
                {:persistent_id=>"6033772", record_id: nil},
                {:persistent_id=>"2345678", record_id: nil},
                {:persistent_id=>"6303325", record_id: nil},
                                             # removed '4248106'
                {:persistent_id=>"3456789", record_id: nil},
                {:persistent_id=>"4567890", record_id: nil},
              ]
            )
          end
        end

        describe '#insert_new_subtitles!' do
          it 'handles default case' do
            default_st_ops_for_file.insert_new_subtitles!(existing_subtitles)
            existing_subtitles.must_equal(
              [
                {:persistent_id=>"1234567", record_id: nil },
                {:persistent_id=>"4329043", record_id: nil },
                {:persistent_id=>"1250739" }, # inserted
                {:persistent_id=>"7453629" }, # inserted
                {:persistent_id=>"6033772", record_id: nil },
                {:persistent_id=>"2345678", record_id: nil },
                {:persistent_id=>"6303325", record_id: nil },
                {:persistent_id=>"4248106", record_id: nil },
                {:persistent_id=>"3456789", record_id: nil },
                {:persistent_id=>"4567890", record_id: nil },
              ]
            )
          end
        end

        describe '#delete_subtitles!' do
          it 'handles default case' do
            default_st_ops_for_file.delete_subtitles!(existing_subtitles)
            existing_subtitles.must_equal(
              [
                {:persistent_id=>"1234567", record_id: nil },
                {:persistent_id=>"4329043", record_id: nil },
                {:persistent_id=>"6033772", record_id: nil },
                {:persistent_id=>"2345678", record_id: nil },
                {:persistent_id=>"6303325", record_id: nil },
                                             # removed '4248106'
                {:persistent_id=>"3456789", record_id: nil},
                {:persistent_id=>"4567890", record_id: nil},
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
