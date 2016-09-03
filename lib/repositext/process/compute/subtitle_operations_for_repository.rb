class Repositext
  class Process
    class Compute

      # Computes subtitle operations for an entire repository. Going from
      # git commit `from_git_commit` to git commit `to_git_commit`.
      class SubtitleOperationsForRepository

        # Initializes a new instance from high level objects.
        # @param content_type [Repositext::ContentType]
        # @param from_git_commit [String]
        # @param to_git_commit [String]
        # @param file_list [Array<String>] path to files to include
        def initialize(content_type, from_git_commit, to_git_commit, file_list)
          @content_type = content_type
          @repository = @content_type.repository
          @language = @content_type.language
          @from_git_commit = from_git_commit
          @to_git_commit = to_git_commit
          # Convert to repo relative paths
          @file_list = file_list.map { |e| e.sub!(@repository.base_dir, '') }
        end

        # @return [Repositext::Subtitle::OperationsForRepository]
        def compute
          if @repository.latest_commit_sha_local != @to_git_commit
            raise ArgumentError.new(
              [
                "`to_git_commit` is not the latest commit in repo #{ @repository.name }. We haven't confirmed that this works!",
                "Latest git commit: #{ @repository.latest_commit_sha_local.inspect }",
                "to_git_commit: #{ @to_git_commit.inspect }",
              ]
            )
          end

          diff = @repository.diff(
            @from_git_commit,
            @to_git_commit,
            context_lines: 0,
            patience: true
          )

          operations_for_all_files = diff.patches.map { |patch|
            file_name = patch.delta.old_file[:path]
            next nil  if !@file_list.include?(file_name)

files_that_break_during_sync_primary_repo = %w[
  55-0123e_0228
  55-0220a_0229
  55-0302_0240
  55-0501a_2074
  55-0611_0256
  55-0625_0261
  55-1115_0291
  56-1002a_0358
  57-0127a_0382
  58-0515_0506
  61-0120_0728
  63-0317m_0942
]
next nil  if files_that_break_during_sync_primary_repo.any? { |e| file_name.index(e) }

            # Skip non content_at files
            unless file_name =~ /\/content\/.+\d{4}\.at\z/
              raise "shouldn't get here"
            end

            puts "     - process #{ file_name }"

            # We use the versions of content AT file and STM CSV file as they
            # existed at `from_git_commit`.
            content_at_file_at_from_commit = Repositext::RFile::ContentAt.new(
              '_',
              @language,
              File.join(@repository.base_dir, file_name),
              @content_type
            ).as_of_git_commit(@from_git_commit)
            stm_csv_file_at_from_commit = content_at_file_at_from_commit
                                            .corresponding_subtitle_markers_csv_file
                                            .as_of_git_commit(@from_git_commit)
            soff = SubtitleOperationsForFile.new_from_content_at_file_and_patch(
              content_at_file_at_from_commit,
              stm_csv_file_at_from_commit,
              patch,
              @repository.base_dir,
              {
                from_git_commit: @from_git_commit,
                to_git_commit: @to_git_commit,
              }
            ).compute

            # Return nil if no subtitle operations exist for this file
            soff.operations.any? ? soff : nil
          }.compact

          ofr = Repositext::Subtitle::OperationsForRepository.new(
            {
              repository: @repository.name,
              from_git_commit: @from_git_commit,
              to_git_commit: @to_git_commit,
            },
            operations_for_all_files
          )

          ofr
        end

      end

    end
  end
end
