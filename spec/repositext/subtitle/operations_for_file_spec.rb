require_relative '../../helper'

class Repositext
  class Subtitle
    describe OperationsForFile do
      let(:contents) { "_" }
      let(:language) { Language::English.new }
      let(:filename) { '/content/57/eng57-0103_1234.at' }

      let(:default_content_at_file) {
        f = RFile::ContentAt.new(contents, language, filename)
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
      "affected_stids": [
        {
          "stid": "4329043",
          "record_id": null,
          "before": "word1 word2 word3, word4 word5. word6 word7 word8. word9, word10 word11 word12. ",
          "after": "word1 word2 word3, word4 word5. word6 word7 word8. "
        },
        {
          "stid": "1250739",
          "record_id": null,
          "before": "",
          "after": "word9, word10 word11 word12. word13 word14 word15 word16. "
        }
      ]
    },
    {
      "operation_id": "0-2",
      "operation_type": "move_right",
      "affected_stids": [
        {
          "stid": "1250739",
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

      describe '.from_json/.from_hash and #to_json/#to_hash (round_trip)' do
        it "handles default case" do
          OperationsForFile.from_json(default_content_at_file, default_json)
                           .to_json.must_equal(default_json)
        end
      end

      describe '#adds_or_removes_subtitles?' do
        it 'handles default case' do
          default_st_ops_for_file.adds_or_removes_subtitles?.must_equal(true)
        end
      end

      describe '#insert_and_split_ops' do
        it 'handles default case' do
          default_st_ops_for_file.delete_and_merge_ops.must_equal([merge_op])
        end
      end

      describe '#insert_and_split_ops' do
        it 'handles default case' do
          default_st_ops_for_file.insert_and_split_ops.must_equal([split_op])
        end
      end

      describe '#lang_code_3_chars' do
        it 'handles default case' do
          default_st_ops_for_file.lang_code_3_chars.must_equal(:eng)
        end
      end

      describe '#product_identity_id' do
        it 'handles default case' do
          default_st_ops_for_file.product_identity_id.must_equal('1234')
        end
      end

      describe '#subtitles_count_delta' do
        it 'handles default case' do
          default_st_ops_for_file.subtitles_count_delta.must_equal(0)
        end
      end

    end
  end
end
