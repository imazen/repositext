# encoding UTF-8
require_relative '../helper'

class Repositext

  describe Repository do

    let(:default_repo_name) { 'static' }
    let(:dir_in_test_repo) {
      File.expand_path("../../git_test/repos/#{ default_repo_name }", __FILE__)
    }
    let(:file_in_test_repo) { File.join(dir_in_test_repo, 'Readme.md') }
    let(:default_repository) {
      Repository::Test.create!(default_repo_name)
      Repository.new(dir_in_test_repo)
    }
    let(:default_git_branch_name) { 'master' }

    describe '#base_dir' do
      it 'handles default data' do
        default_repository.base_dir.must_equal(dir_in_test_repo + '/')
      end
    end

    describe '#current_branch_name' do
      it 'handles default data' do
        default_repository.current_branch_name.must_equal(default_git_branch_name)
      end
    end

    describe '#head_ref' do
      it 'handles default data' do
        default_repository.head_ref.must_be_instance_of(Rugged::Reference)
      end
    end

    describe '#latest_commit' do
      it 'handles default data' do
        r = default_repository.latest_commit(file_in_test_repo)
        r.must_be_instance_of(Rugged::Commit)
      end
    end

    describe '#latest_commit_sha_local' do
      it 'handles default data' do
        r = default_repository.latest_commit_sha_local(file_in_test_repo)
        r.must_equal('25018531db326bcff325fcf8f7350526b7bc1f4f')
      end
    end

    describe '#latest_commit_sha_remote' do
      it 'handles default data' do
        r = default_repository.latest_commit_sha_remote(
          'origin', 'master'
        )
        r.must_equal('')
      end
    end

    describe '#latest_commits_local' do
      it 'handles default data' do
        r = default_repository.latest_commits_local
        r.must_equal(
          [
            {
              commit_hash: "2501853",
              author: "Jo Hund",
              date: "2015-10-26",
              message: "Initial commit",
            }
          ]
        )
      end
    end

    describe '#lookup' do
      it 'handles default data' do
        default_repository.lookup(
          "2501853"
        ).must_be_instance_of(Rugged::Commit)
      end
    end

    describe '#name' do
      it 'handles default data' do
        default_repository.name.must_equal(default_repo_name)
      end
    end

    describe '#repo_path' do
      it 'handles default data' do
        default_repository.repo_path.must_equal(
          File.join(dir_in_test_repo, '.git', '')
        )
      end
    end

  end
end
