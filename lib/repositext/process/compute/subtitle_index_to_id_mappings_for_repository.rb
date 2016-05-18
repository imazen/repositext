class Repositext
  class Process
    class Compute

      # Computes mappings of subtitle indexes to persistent ids for an entire
      # repository. Going from git commit `fromGitCommit` to git commit `toGitCommit`.
      class SubtitleIndexToIdMappingsForRepository

        # Initializes a new instance from high level objects.
        # @param repository [Repositext::Repository]
        # @param fromGitCommit [String]
        # @param toGitCommit [String]
        def initialize(repository, fromGitCommit, toGitCommit)
          # repo_root = '/Users/johund/development/vgr-english'
          # repository = Rugged::Repository.new(repo_root)
          @repository = repository
          @fromGitCommit = fromGitCommit
          @toGitCommit = toGitCommit
        end

        # @return [Repositext::Subtitle::OperationsForRepository]
        def compute
          diff = @repository.diff(@fromGitCommit, @toGitCommit, context_lines: 0)
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
              fromGitCommit: @fromGitCommit,
              toGitCommit: @toGitCommit,
            },
            mappings_for_all_files
          )
        end

      end

    end
  end
end
