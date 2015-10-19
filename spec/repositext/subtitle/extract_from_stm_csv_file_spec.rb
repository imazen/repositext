require_relative '../../helper'

class Repositext
  class Subtitle
    describe ExtractFromStmCsvFile do

      let(:inventory_file) {
        FileLikeStringIO.new('_path', "abcd\nefgh\n", 'r+')
      }

      describe '#load_subtitle_marks_from_csv_file' do
        it "loads stms" do
          stm_csv_file = FileLikeStringIO.new(
            'subtitle_markers.csv',
            [
              "relativeMS\tsamples\tcharLength\tpersistentId\trecordId",
              "0\t0\t54\tpid1\trid1",
              "6083\t268277\t78\tpid2\trid2",
              "7659\t606043\t102\tpid3\trid3",
            ].join("\n")
          )
          c = JsonLuceneVgr.send(:new, '_', {})
          c.send(:load_subtitle_marks_from_csv_file, stm_csv_file).must_equal(
            [
              true,
              [
                { absolute_milliseconds: 0, persistent_id: 'pid1', record_id: 'rid1' },
                { absolute_milliseconds: 6083, persistent_id: 'pid2', record_id: 'rid2' },
                { absolute_milliseconds: 13742, persistent_id: 'pid3', record_id: 'rid3' },
              ]
            ]
          )
        end
      end

    end
  end
end
