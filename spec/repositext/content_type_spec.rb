# encoding UTF-8
require_relative '../helper'

class Repositext

  describe ContentType do
    let(:content_type_name) { 'general' }

    let(:primary_repo_name) { 'rt-english' }
    let(:path_to_primary_repo) {
      File.join(Repository::Test.repos_folder, primary_repo_name, '')
    }
    let(:primary_repo) {
      Repository::Test.create!(primary_repo_name)
      Repository::Content.new(path_to_primary_repo)
    }
    let(:path_to_primary_content_type) {
      File.join(primary_repo.base_dir, "ct-#{ content_type_name }", '')
    }
    let(:primary_content_type) {
      ContentType.new(path_to_primary_content_type)
    }

    let(:foreign_repo_name) { 'rt-spanish' }
    let(:path_to_foreign_repo) {
      File.join(Repository::Test.repos_folder, foreign_repo_name, '')
    }
    let(:foreign_repo) {
      Repository::Test.create!(foreign_repo_name)
      Repository::Content.new(path_to_foreign_repo)
    }
    let(:path_to_foreign_content_type) {
      File.join(foreign_repo.base_dir, "ct-#{ content_type_name }", '')
    }
    let(:foreign_content_type) {
      ContentType.new(path_to_foreign_content_type)
    }

    describe '#initialize' do
      it 'initializes with default data' do
        ContentType.new(path_to_foreign_content_type).name.must_equal(content_type_name)
      end
    end

    describe '#repository' do
      it 'has correct repository' do
        primary_content_type.repository.base_dir.must_equal(path_to_primary_repo)
      end
    end

    describe '#name' do
      it 'has correct name' do
        primary_content_type.name.must_equal(content_type_name)
      end
    end

    describe '#config' do
      it 'has correct primary config' do
        primary_content_type.config.must_be_instance_of(Repositext::Cli::Config)
      end
    end

    describe '#corresponding_primary_content_type' do
      it 'has correct content_type' do
        foreign_content_type.corresponding_primary_content_type.base_dir.must_equal(path_to_primary_content_type)
      end
    end

    describe '#corresponding_primary_content_type_base_dir' do
      it 'has correct content_type base_dir' do
        foreign_content_type.corresponding_primary_content_type_base_dir.must_equal(path_to_primary_content_type)
      end
    end

    describe '#is_primary_content_type' do
      it 'handles default primary data' do
        primary_content_type.is_primary_content_type.must_equal(true)
      end

      it 'handles default foreign data' do
        foreign_content_type.is_primary_content_type.must_equal(false)
      end
    end

    describe '#language' do
      it 'handles default primary data' do
        primary_content_type.language.name.must_equal('English')
      end

      it 'handles default foreign data' do
        foreign_content_type.language.name.must_equal('Spanish')
      end
    end

  end

end
