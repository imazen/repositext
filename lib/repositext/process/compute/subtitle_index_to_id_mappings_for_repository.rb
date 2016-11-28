class Repositext
  class Process
    class Compute

      # Computes mappings of subtitle indexes to persistent ids for an entire
      # repository. Going from git commit `from_git_commit` to git commit `to_git_commit`.
      class SubtitleIndexToIdMappingsForRepository

        # Initializes a new instance from high level objects.
        # @param repository [Repositext::Repository]
        # @param from_git_commit [String]
        # @param to_git_commit [String]
        def initialize(repository, from_git_commit, to_git_commit)
          @repository = repository
          @from_git_commit = from_git_commit
          @to_git_commit = to_git_commit
        end

        # @return [Repositext::Subtitle::OperationsForRepository]
        def compute
          diff = @repository.diff(@from_git_commit, @to_git_commit, context_lines: 0)
          mappings_for_all_files = diff.patches.map { |patch|
            file_name = patch.delta.old_file[:path]
next nil  unless file_name =~ /\/eng64-0212/
            # Skip non content_at files
            next nil  unless file_name =~ /\Acontent\/.+\d{4}\.at\z/
            file_path = File.join(@repository.base_dir, file_name)
            content_at_file = Repositext::RFile::ContentAt.new(
              File.read(file_path),
              Repositext::Language.find_by_code(:eng), # TODO: Get this from repo!
              file_path,
              @repository
            )
            SubtitleIndexToIdMappingsForFile.new_from_content_at_file_and_patch(
              content_at_file,
              patch
            ).compute
          }.compact
          Repositext::Subtitle::IndexToIdMappingsForRepository.new(
            {
              repository: @repository.name,
              from_git_commit: @from_git_commit,
              to_git_commit: @to_git_commit,
            },
            mappings_for_all_files
          )
        end

      end

    end
  end
end
