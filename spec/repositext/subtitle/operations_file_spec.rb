require_relative '../../helper'

class Repositext
  class Subtitle
    describe OperationsFile do

      describe '.compute_from_to_git_commit_marker' do
        [
          ['1234567', '987654321', '123456-to-987654'],
        ].each do |from_commit, to_commit, xpect|
          it "handles #{ [from_commit, to_commit].inspect }" do
            OperationsFile.compute_from_to_git_commit_marker(
              from_commit,
              to_commit
            ).must_equal(xpect)
          end
        end
      end

      describe '.compute_latest_to_commit' do
        # TBD
      end

      describe '.compute_next_file_path' do
        it 'handles default case' do
          OperationsFile.compute_next_file_path(
            '/st-ops/dir/',
            'fromCommit',
            'toCommit',
            DateTime.new(2016,8,13,19,43,42)
          ).must_equal(
            '/st-ops/dir/st-ops-2016_08_13-19_43_42-fromCo-to-toComm.json'
          )
        end
      end

      describe '.compute_next_file_sequence_marker' do
        # TBD
      end

      describe '.detect_st_ops_file_path' do
        # TBD
      end

      describe '.extract_from_and_to_commit_from_filename' do
        [
          ['/some/path/st-ops-2016_08_13-19_43_04-791a1d-to-eea8b4.json', ['791a1d', 'eea8b4']],
        ].each do |filename, xpect|
          it "handles #{ filename.inspect }" do
            OperationsFile.extract_from_and_to_commit_from_filename(
              filename
            ).must_equal(xpect)
          end
        end
      end

      describe '.find_latest' do
        # TBD
      end

      describe '.get_all_st_ops_files' do
        # TBD
      end

      describe '.get_all_sync_commits' do
        # TBD
      end

      describe '.get_sync_commits' do
        # TBD
      end

    end
  end
end
