# encoding UTF-8
require_relative '../../helper'

class Repositext
  class Repository
    describe Test do

      let(:default_image_names) {
        %w[
          rt-english
          rt-spanish
          static
        ]
      }
      let(:default_repo_name) { 'static' }

      describe '.create!' do

        it 'creates a single repo' do
          Test.delete!
          Test.create!(default_repo_name)
          Test.all_repo_names.must_equal([default_repo_name])
        end

        it 'creates repos from all available images' do
          Test.delete!
          Test.create!
          Test.all_repo_names.must_equal(default_image_names)
        end

      end

      describe '.delete!' do

        it 'deletes a single repo' do
          Test.create!(default_repo_name)
          Test.delete!(default_repo_name)
          Test.all_repo_names.wont_include(default_repo_name)
        end

        it 'deletes all existing repos' do
          Test.delete!
          Test.all_repo_names.must_equal([])
        end

      end

      describe '.all_image_names' do

        it 'returns the correct value' do
          Test.all_image_names.must_equal(default_image_names)
        end

      end

      describe '.all_repo_names' do

        it 'returns an empty array when all are deleted' do
          Test.delete!
          Test.all_repo_names.must_equal([])
        end

        it 'returns names of individual repo' do
          Test.delete!
          Test.create!(default_repo_name)
          Test.all_repo_names.must_equal([default_repo_name])
        end

        it 'returns names of all repos' do
          Test.delete!
          Test.create!
          Test.all_repo_names.must_equal(default_image_names)
        end

      end

      describe '.images_folder' do
        it 'returns the correct value' do
          Test.images_folder.must_match(/repositext\/spec\/git_test\/repo_images\z/)
        end
      end

      describe '.repos_folder' do
        it 'returns the correct value' do
          Test.repos_folder.must_match(/repositext\/spec\/git_test\/repos\z/)
        end
      end

    end
  end
end
