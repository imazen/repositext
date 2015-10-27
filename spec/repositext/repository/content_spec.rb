# encoding UTF-8
require_relative '../../helper'

class Repositext
  class Repository
    describe Content do

      let(:primary_repo_name) { 'rt-english' }
      let(:foreign_repo_name) { 'rt-spanish' }
      let(:path_to_primary_repo) {
        File.join(Repository::Test.repos_folder, primary_repo_name)
      }
      let(:path_to_foreign_repo) {
        File.join(Repository::Test.repos_folder, foreign_repo_name)
      }
      let(:primary_repo) {
        Repository::Test.create!('rt-english')
        Repository::Content.new(path_to_primary_repo)
      }
      let(:foreign_repo) {
        Repository::Test.create!('rt-spanish')
        Repository::Content.new(path_to_foreign_repo)
      }

      describe '#initialize' do

        it 'initializes from repo_path' do
          r = Content.new(primary_repo.base_dir)
          r.config.must_be_instance_of(Repositext::Cli::Config)
        end

        it 'initializes from config' do
          r = Content.new(primary_repo.config)
          r.config.must_be_instance_of(Repositext::Cli::Config)
        end

      end

      describe '#corresponding_primary_repository' do
        it 'handles default data' do
          # Can't compare repo instances directly since they are different.
          # use repo.base_dir as proxy.
          foreign_repo.corresponding_primary_repository.base_dir.must_equal(
            primary_repo.base_dir
          )
        end
      end

      describe '#corresponding_primary_repo_base_dir' do
        it 'handles default data' do
          foreign_repo.corresponding_primary_repo_base_dir.must_equal(
            primary_repo.base_dir
          )
        end
      end

      describe '#is_primary_repo' do
        it 'handles default data' do
          primary_repo.is_primary_repo.must_equal(true)
          foreign_repo.is_primary_repo.must_equal(false)
        end
      end

      describe '#language' do
        it 'handles default data' do
          primary_repo.language.name.must_equal('English')
          foreign_repo.language.name.must_equal('Spanish')
        end
      end


    end
  end
end
