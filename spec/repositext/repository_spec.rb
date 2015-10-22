# encoding UTF-8
require_relative '../helper'

class Repositext

  describe Repository do

    # Uses this code repo as test data
    let(:dir_in_repo) { Dir.pwd + '/' }
    let(:default_repository) { Repository.new(dir_in_repo) }
    # make branch name configurable for development in other branches
    let(:git_branch_name) { 'wip/refactor' }

    describe '#base_dir' do
      it 'handles default data' do
        # base_dir must be substring of dir_in_repo
        dir_in_repo.index(default_repository.base_dir).must_equal(0)
      end
    end

    describe '#current_branch_name' do
      it 'handles default data' do
        default_repository.current_branch_name.must_equal(git_branch_name)
      end
    end

    describe '#head_ref' do
      it 'handles default data' do
        default_repository.head_ref.must_be_instance_of(Rugged::Reference)
      end
    end

    describe '#latest_commit' do
      it 'handles default data' do
        default_repository.latest_commit(
          File.expand_path(__FILE__)
        ).must_be_instance_of(Rugged::Commit)
      end
    end

    describe '#latest_commit_sha_local' do
      it 'handles default data' do
        r = default_repository.latest_commit_sha_local(
          File.expand_path(__FILE__)
        )
        # We're looking for a reference string like this:
        # '350029aa42708cd51dbfed52bf32f58886c2dd5b'
        r.must_be_instance_of(String)
        r.length.must_equal(40)
      end
    end

    describe '#latest_commit_sha_remote' do
      it 'handles default data' do
        r = default_repository.latest_commit_sha_remote(
          'origin', 'master'
        )
        # We're looking for a reference string like this:
        # '350029aa42708cd51dbfed52bf32f58886c2dd5b'
        r.must_be_instance_of(String)
        r.length.must_equal(40)
      end
    end

    describe '#latest_commits_local' do
      it 'handles default data' do
        # We're looking for presence of hash expected keys in latest commit.
        default_repository.latest_commits_local(
          File.expand_path(__FILE__),
          1
        ).first.keys.must_equal([:commit_hash, :author, :date, :message])
      end
    end

    describe '#lookup' do
      it 'handles default data' do
        # We check for a commit we know exists.
        default_repository.lookup(
          '87a9cbc15a5657bf35e965e7bada246aad940889'
        ).must_be_instance_of(Rugged::Commit)
      end
    end

    describe '#name' do
      it 'handles default data' do
        default_repository.name.must_equal('repositext')
      end
    end

    describe '#repo_path' do
      it 'handles default data' do
        # We're looking for a local path that ends with '/repositext/.git'
        default_repository.repo_path.must_match(/\/repositext\/\.git\/\z/)
      end
    end

  end
end
