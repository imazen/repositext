class Repositext
  class Process
    class Compute

      # Computes subtitle operations for an entire repository. Going from
      # git commit `fromGitCommit` to git commit `toGitCommit`.
      class SubtitleOperationsForRepository

        # Initializes a new instance from high level objects.
        # @param content_type [Repositext::ContentType]
        # @param fromGitCommit [String]
        # @param toGitCommit [String]
        # @param file_list [Array<String>] path to files to include
        def initialize(content_type, fromGitCommit, toGitCommit, file_list)
          @content_type = content_type
          @repository = @content_type.repository
          @language = @content_type.language
          @fromGitCommit = fromGitCommit
          @toGitCommit = toGitCommit
          # Convert to repo relative paths
          @file_list = file_list.map { |e| e.sub!(@repository.base_dir, '') }
        end

        # @return [Repositext::Subtitle::OperationsForRepository]
        def compute
          if @repository.latest_commit_sha_local != @toGitCommit
            raise ArgumentError.new(
              [
                "`toGitCommit` is not the latest commit in repo. We haven't confirmed that this works!",
                "Latest git commit: #{ @repository.latest_commit_sha_local.inspect }",
                "toGitCommit: #{ @toGitCommit.inspect }",
              ]
            )
          end

          diff = @repository.diff(@fromGitCommit, @toGitCommit, context_lines: 0)

          operations_for_all_files = diff.patches.map { |patch|
            file_name = patch.delta.old_file[:path]
            next nil  if !@file_list.include?(file_name)

            # Skip non content_at files
            unless file_name =~ /\/content\/.+\d{4}\.at\z/
              raise "shouldn't get here"
            end

            puts "   - processing #{ file_name }"

            # We use the versions of content AT file and STM CSV file as they
            # existed at `fromGitCommit`.
            content_at_file_at_from_commit = Repositext::RFile::ContentAt.new(
              '_',
              @language,
              File.join(@repository.base_dir, file_name),
              @content_type
            ).as_of_git_commit(@fromGitCommit)
            stm_csv_file_at_from_commit = content_at_file_at_from_commit
                                            .corresponding_subtitle_markers_csv_file
                                            .as_of_git_commit(@fromGitCommit)
            soff = SubtitleOperationsForFile.new_from_content_at_file_and_patch(
              content_at_file_at_from_commit,
              stm_csv_file_at_from_commit,
              patch,
              @repository.base_dir,
              {
                from_git_commit: @fromGitCommit,
                to_git_commit: @toGitCommit,
              }
            ).compute

            # Return nil if no subtitle operations exist for this file
            soff.operations.any? ? soff : nil
          }.compact

          ofr = Repositext::Subtitle::OperationsForRepository.new(
            {
              repository: @repository.name,
              fromGitCommit: @fromGitCommit,
              toGitCommit: @toGitCommit,
            },
            operations_for_all_files
          )

          ofr
        end

      end

    end
  end
end
