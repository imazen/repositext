# Class to manage creation and deletion of test git repositories.
class Repositext
  class Repository

    # We have to do some extra steps to create test git repos inside the `repositext`
    # git repo since git doesn't allow nested independent repos.

    # So here is what we do:

    # * We `.gitignore` the `spec/git_test/repos` directory. This gives us a place
    #   where we can have nested independent repos without interfering with the
    #   parent `repositext` repo.
    # * We create test repos inside `spec/git_test/repos` from images stored in
    #   `spec/git_test/repo_images`.
    # * We track the test repo images under the main `repositext` git repo. This
    #   is possible because we rename the test repos' `.git` directory to `dot_git`.
    #   This gives us an image of a git repo with all the git binary files without
    #   it actually being a git repo.
    # * In order to create a test git repo from an image, we copy all the files
    #   from the `test_images` folder to the `repos` folder and then rename the
    #   `dot_git` directory to `.git`. This creates a valid git repo inside a
    #   `.gitignore`d folder.

    # This process allows us to have the test git repos under version control for
    # cloning and distribution, and it gives us nested working git repos for testing.

    # To initialize all test git repos from their respective images:

    #     Repositext::Repository::Test.initialize

    # To initialize a single test git repo:

    #     Repositext::Repository::Test.initialize('rt-english')
    class Test

      # Creates a test git repository. Will override repo if it exists already.
      # @param image_name [String, optional] creates repo from image with image_name
      #     or from all available images if not given.
      # @return [Array<String>] paths to all created repositories
      def self.create!(image_name=nil)
        image_names = image_name ? [image_name] : all_image_names
        image_names.each { |name|
          delete!(name) # First delete existing repo
          # Copy image
          FileUtils.mkdir_p(repos_folder)
          FileUtils.cp_r(
            File.join(images_folder, name),
            repos_folder
          )
          # Rename `dot_git` => `.git` to make it a live repo
          path_to_dot_git = File.join(repos_folder, name, 'dot_git')
          FileUtils.mv(
            path_to_dot_git,
            path_to_dot_git.sub('dot_git', '.git')
          )
        }
        image_names.map { |e| File.join(repos_folder, e) }
      end

      # Deletes a test git repository. No-op if repo with `repo_name` doesn't exist.
      # @param repo_name [String, optional] delete repo with repo_name
      #     or all repos inside `.repos_folder` if not given.
      # @return [Array<String>] names of all deleted repositories
      def self.delete!(repo_name=nil)
        repo_names = repo_name ? [repo_name] : all_repo_names
        repo_names.each { |name|
          file_path = File.join(repos_folder, name)
          next  if !File.exist?(file_path)
          FileUtils.rm_r(file_path)
        }
      end

      # Returns names of all repo images available.
      # @return [Array<String>]
      def self.all_image_names
        Dir.glob("#{ images_folder }/*").map { |e|
          e.sub(images_folder + '/', '')
        }
      end

      # Returns names of all live test repos that currently exist.
      # @return [Array<String>]
      def self.all_repo_names
        Dir.glob("#{ repos_folder }/*").map { |e|
          e.sub(repos_folder + '/', '')
        }
      end

      # Returns an absolute path to the folder that contains available repository images.
      # @return [String]
      def self.images_folder
        File.expand_path('../../../../spec/git_test/repo_images', __FILE__)
      end

      # Returns an absolute path to the folder that contains live repositories.
      # @return [String]
      def self.repos_folder
        File.expand_path('../../../../spec/git_test/repos', __FILE__)
      end

    end
  end
end
