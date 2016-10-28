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
        # @param prev_last_operation_id [Integer] previous sync's last operation_id
        def initialize(content_type, from_git_commit, to_git_commit, file_list, is_initial_sync, prev_last_operation_id)
          @content_type = content_type
          @repository = @content_type.repository
          @language = @content_type.language
          @from_git_commit = from_git_commit
          @is_initial_sync = is_initial_sync
          @first_operation_id = prev_last_operation_id + 1
          @prev_last_operation_id = prev_last_operation_id
          @to_git_commit = to_git_commit
          # Convert to repo relative paths
          @file_list = file_list.map { |e| e.sub!(@repository.base_dir, '') }
          # Uncomment this code to collect statistic related to subtitles.
          # $repositext_subtitle_length_distribution = Hash.new(0)
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

          operations_for_all_files = if @is_initial_sync
            process_all_primary_files
          else
            process_primary_files_with_changes_only
          end

          # Uncomment this code to collect statistic related to subtitles.
          # p $repositext_subtitle_length_distribution

          last_operation_id = operations_for_all_files.last.last_operation_id

          ofr = Repositext::Subtitle::OperationsForRepository.new(
            {
              repository: @repository.name,
              from_git_commit: @from_git_commit,
              to_git_commit: @to_git_commit,
              first_operation_id: @first_operation_id,
              last_operation_id: last_operation_id,
            },
            operations_for_all_files
          )
          ofr
        end

        # Returns array with operations for all primary files
        def process_all_primary_files
          # NOTE: I investigated concurrent processing of files
          # to speed up this process, however I didn't pursue it
          # further: This process is highly CPU intensive, so the
          # only way to get a significant speedup is to use
          # multiple CPUs/Cores. In MRI this is only possible
          # with multiple processes. I didn't want to go through
          # the trouble of IPC to collect all files' operations.
          # It would be easier if we could use threads, however
          # that would require jruby or rbx. So I'm sticking with
          # sequential processing for now.
          Dir.glob(
            File.join(@repository.base_dir, '**/content/**/*.at')
          ).map { |absolute_file_path|
            next nil  if !@file_list.any? { |e| absolute_file_path.index(e) }
            # Skip non content_at files
            unless absolute_file_path =~ /\/content\/.+\d{4}\.at\z/
              raise "shouldn't get here"
            end

            content_at_file_to = Repositext::RFile::ContentAt.new(
              File.read(absolute_file_path),
              @language,
              absolute_file_path,
              @content_type
            )

            puts "     - process #{ content_at_file_to.repo_relative_path }"

            soff = SubtitleOperationsForFile.new(
              content_at_file_to,
              @repository.base_dir,
              {
                from_git_commit: @from_git_commit,
                to_git_commit: @to_git_commit,
                prev_last_operation_id: @prev_last_operation_id,
              }
            ).compute

            if soff.operations.any?
              @prev_last_operation_id = soff.last_operation_id
              soff
            else
              # Return nil if no subtitle operations exist for this file
              nil
            end
          }.compact
        end

        # Returns array with operations for primary files that changed only
        def process_primary_files_with_changes_only
          # We get the diff only so that we know which files have changed.
          diff = @repository.diff(@from_git_commit, @to_git_commit, context_lines: 0)

          diff.patches.map { |patch|
            file_name = patch.delta.old_file[:path]
            next nil  if !@file_list.include?(file_name)

            # next nil  if !file_name.index('63-0728')

            # Skip non content_at files
            unless file_name =~ /\/content\/.+\d{4}\.at\z/
              raise "shouldn't get here"
            end

            puts "     - process #{ file_name }"

            absolute_file_path = File.join(@repository.base_dir, file_name)
            content_at_file_to = Repositext::RFile::ContentAt.new(
              File.read(absolute_file_path),
              @language,
              absolute_file_path,
              @content_type
            )

            soff = SubtitleOperationsForFile.new(
              content_at_file_to,
              @repository.base_dir,
              {
                from_git_commit: @from_git_commit,
                to_git_commit: @to_git_commit,
                prev_last_operation_id: @prev_last_operation_id,
              }
            ).compute

            if soff.operations.any?
              @prev_last_operation_id = soff.last_operation_id
              soff
            else
              # Return nil if no subtitle operations exist for this file
              nil
            end
          }.compact
        end

      end
    end
  end
end
