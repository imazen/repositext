class Repositext
  class Process
    class Compute

      # Computes subtitle operations for an entire (primary) repository.
      # Going from git commit `from_git_commit` to git commit `to_git_commit`.
      # This will never be done for foreign repositories.
      class SubtitleOperationsForRepository

        # Initializes a new instance from high level objects.
        # @param content_type [Repositext::ContentType]
        # @param from_git_commit [String] SHA1
        # @param to_git_commit [String] SHA1
        # @param file_list [Array<String>] path to files to include
        # @param is_initial_primary_sync [Boolean] set to true for initial sync only
        # @param prev_last_operation_id [Integer] previous sync's last operation_id
        def initialize(content_type, from_git_commit, to_git_commit, file_list, is_initial_primary_sync, prev_last_operation_id)
          @content_type = content_type
          @repository = @content_type.repository
          @language = @content_type.language
          @from_git_commit = from_git_commit
          @is_initial_primary_sync = is_initial_primary_sync
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

          operations_for_all_files = if @is_initial_primary_sync
            process_all_primary_files
          else
            process_primary_files_with_changes_only
          end

          # Uncomment this code to collect statistic related to subtitles.
          # p $repositext_subtitle_length_distribution

          # Manage operation ids.
          # We have to handle the normal situation where there are subtitle
          # operations in all affected files.
          # In addition to that we handle cases where:
          # * there are no files with operations in the entire repo.
          # * the trailing files in the repo have no operations.
          # We get files with no operations when the only changes are to time
          # slices in the STM CSV files.
          # If an OperationsForRepository has no operations (time slice changes
          # only), then we re-use the @prev_last_operation_id for both
          # first_operation_id and last_operation_id.
          # If an OperationsForRepository has operations, however the trailing
          # file or files have none, then we use the last operation_id from the
          # last file that has operations.
          last_op_ids = operations_for_all_files.map { |soff|
            soff.last_operation_id
          }.compact

          first_operation_id, last_operation_id = if [] == last_op_ids
            # No operations found.
            # Use @first_operation_id minus one (to get previous st_sync's last
            # op id) for both first and last.
            [@first_operation_id - 1, @first_operation_id - 1]
          else
            # Use last entry in last_operation_ids. The compact method got rid
            # of any trailing nil entries if the last operations were time slice
            # changes only.
            [@first_operation_id, last_op_ids.last]
          end

          ofr = Repositext::Subtitle::OperationsForRepository.new(
            {
              repository: @repository.name,
              from_git_commit: @from_git_commit,
              to_git_commit: @to_git_commit,
              first_operation_id: first_operation_id,
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

            puts "     - process #{ content_at_file_to.repo_relative_path(true) }"

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

        # Returns array with operations for primary files that have changed.
        # We determine change through the union of the following two:
        # * Any files where there is a diff in the content AT file.
        # * Any files that have the `st_sync_required` flag set to true (because
        #   of changes to time slices in STM CSV file).
        # @return [Array<SubtitleOperationsForFile>]
        def process_primary_files_with_changes_only
          # We get the diff only so that we know which files have changed.
          diff = @repository.diff(@from_git_commit, @to_git_commit, context_lines: 0)
          fwc = []
          diff.patches.each { |patch|
            file_name = patch.delta.old_file[:path]

            # Skip non content_at files
            next  if !@file_list.include?(file_name)
            # next  if !file_name.index('63-0728')
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
              # Only collect files that have subtitle operations
              @prev_last_operation_id = soff.last_operation_id
              fwc << soff
            end
          }

          # Then we add any files that have st_sync_required set to true and are
          # not in fwc already.
          @file_list.each { |content_at_filename|
            # Skip files that we have captured already
            next  if fwc.any? { |soff| soff.content_at_file.repo_relative_path == content_at_filename }
            # Skip files that don't have st_sync_required set to true
            dj_filename = content_at_filename.sub(/\.at\z/, '.data.json')
            dj_file = Repositext::RFile::DataJson.new(
              File.read(dj_filename),
              @language,
              dj_filename,
              @content_type
            )
            next  if !dj_file.read_data['st_sync_required']
            # This file is not in the list of fwc yet, and it has st_sync_required.
            # We add an soff instance with no operations. This could be a file
            # that has changes to subtitle timeslices only.
            content_at_file = Repositext::RFile::ContentAt.new(
              File.read(content_at_filename),
              @language,
              content_at_filename,
              @content_type
            )
            soff = Repositext::Subtitle::OperationsForFile.new(
              content_at_file,
              {
                file_path: content_at_file.repo_relative_path,
                from_git_commit: @from_git_commit,
                to_git_commit: @to_git_commit,
              },
              [] # No operations
            )
            fwc << soff
          }
          # Return list of unique files with changes
          fwc.uniq
        end

      end
    end
  end
end
