class Repositext
  class Process
    class Compute

      # Computes subtitle operations for an entire (primary) repository.
      # Going from git commit `from_git_commit` to git commit `to_git_commit`.
      # This will never be done for foreign repositories.
      class SubtitleOperationsForRepository

        # Initializes a new instance from high level objects.
        # @param any_content_type [Repositext::ContentType]
        # @param from_git_commit [String] SHA1
        # @param to_git_commit [String] SHA1
        # @param from_table_release_version [String, Nil] just passed through to st_ops file. Can be nil if not applicable.
        # @param to_table_release_version [String, Nil] just passed through to st_ops file. Can be nil if not applicable.
        # @param file_list [Array<String>] path to files to include
        # @param is_initial_primary_sync [Boolean] set to true for initial sync only
        # @param prev_last_operation_id [Integer] previous sync's last operation_id
        # @param execution_context [Symbol] one of :compute_new_st_ops or :recompute_existing_st_ops
        def initialize(
          any_content_type,
          from_git_commit,
          to_git_commit,
          from_table_release_version,
          to_table_release_version,
          file_list,
          is_initial_primary_sync,
          prev_last_operation_id,
          execution_context
        )
          @any_content_type = any_content_type
          @repository = @any_content_type.repository
          @language = @any_content_type.language

          @from_git_commit = from_git_commit
          @to_git_commit = to_git_commit
          @from_table_release_version = from_table_release_version
          @to_table_release_version = to_table_release_version
          @is_initial_primary_sync = is_initial_primary_sync
          @prev_last_operation_id = prev_last_operation_id
          @execution_context = execution_context
          @logger = Repositext::Utils::CommandLogger.new

          @first_operation_id = prev_last_operation_id + 1
          # Convert to repo relative paths
          @file_list = file_list.map { |e| e.sub!(@repository.base_dir, '') }
          # Uncomment this code to collect statistic related to subtitles.
          # $repositext_subtitle_length_distribution = Hash.new(0)
        end

        # @return [Repositext::Subtitle::OperationsForRepository]
        def compute
          case @execution_context
          when :compute_new_st_ops
            # Regular st sync: We expect @to_git_commit to be the latest
            # git commit in the repo.
            if @repository.latest_commit_sha_local != @to_git_commit
              raise ArgumentError.new(
                "`to_git_commit` must be the latest commit in repo #{ @repository.name }: #{ @repository.latest_commit_sha_local.inspect }, however it is #{ @to_git_commit.inspect }."
              )
            end
          when :recompute_existing_st_ops
            # This is part of table release where we re-compute the combined
            # st ops since the last table release. In this case we check that
            # the @to_git_commit is aligned with existing st_sync commits.
            if !(
              Repositext::Subtitle::OperationsFile.any_with_git_commit?(
                @any_content_type.config_compute_base_dir(:subtitle_operations_dir),
                @to_git_commit
              )
            )
              raise ArgumentError.new(
                "`to_git_commit` must be aligned with an existing sync commit. (#{ @to_git_commit.inspect })"
              )
            end
          else
            raise "Handle this: #{ @execution_context.inspect }"
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
              from_table_release_version: @from_table_release_version,
              to_table_release_version: @to_table_release_version,
              first_operation_id: first_operation_id,
              last_operation_id: last_operation_id,
              language: @language.code_3_chars,
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

            # Note: @any_content_type may be the wrong one, however finding
            # corresponding STM CSV file will still work as it doesn't rely
            # on config but das regex replacements on file path only.
            content_at_file_to = Repositext::RFile::ContentAt.new(
              File.read(absolute_file_path),
              @language,
              absolute_file_path,
              @any_content_type
            )

            @logger.info("     - process #{ content_at_file_to.repo_relative_path(true) }")

            soff = SubtitleOperationsForFile.new(
              content_at_file_to,
              @repository.base_dir,
              {
                from_git_commit: @from_git_commit,
                to_git_commit: @to_git_commit,
                prev_last_operation_id: @prev_last_operation_id,
                execution_context: @execution_context,
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
          # It's ok to use the reference commits because we're dealing with
          # content AT files only.
          diff = @repository.diff(@from_git_commit, @to_git_commit, context_lines: 0)
          fwc = []
          diff.patches.each { |patch|
            file_name = patch.delta.old_file[:path]
            # Skip non content_at files
            next  if !@file_list.include?(file_name)
            # next  if !file_name.index('63-0728')
            unless file_name =~ /\/content\/.+\d{4}\.at\z/
              raise "shouldn't get here: #{ file_name.inspect }"
            end

            @logger.info("     - process #{ file_name }")

            absolute_file_path = File.join(@repository.base_dir, file_name)
            # Initialize content AT file `to` with contents as of `to_git_commit`.
            # It's fine to use the reference sync commit as the sync operation
            # doesn't touch content AT files, only STM CSV ones.
            content_at_file_to = Repositext::RFile::ContentAt.new(
              '_', # Contents are initialized later via `#as_of_git_commit`
              @language,
              absolute_file_path,
              @any_content_type
            ).as_of_git_commit(@to_git_commit)

            compute_st_ops_attrs = {
              from_git_commit: @from_git_commit,
              to_git_commit: @to_git_commit,
              prev_last_operation_id: @prev_last_operation_id,
              execution_context: @execution_context,
            }

            compute_st_ops_attrs = refine_compute_st_ops_attrs(
              compute_st_ops_attrs,
              {
                from_table_release_version: @from_table_release_version,
                to_table_release_version: @to_table_release_version,
                absolute_file_path: absolute_file_path
              }
            )

            soff = SubtitleOperationsForFile.new(
              content_at_file_to,
              @repository.base_dir,
              compute_st_ops_attrs
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
            # Skip files that don't have st_sync_required set to true at to_git_commit
            dj_filename = content_at_filename.sub(/\.at\z/, '.data.json')
            # We use dj file contents at to_git_commit :at_child_or_ref
            dj_file = Repositext::RFile::DataJson.new(
              '_', # Contents are initialized later via #as_of_git_commit
              @language,
              dj_filename,
              @any_content_type
            ).as_of_git_commit(
              @to_git_commit,
              :at_child_or_ref
            )
            next  if(dj_file.nil? || !dj_file.read_data['st_sync_required'])
            # This file is not in the list of fwc yet, and it has st_sync_required.
            # We add an soff instance with no operations. This could be a file
            # that has changes to subtitle timeslices only.
            content_at_file_from = Repositext::RFile::ContentAt.new(
              '_', # Contents are initialized later via `#as_of_git_commit`
              @language,
              content_at_filename,
              @any_content_type
            ).as_of_git_commit(@from_git_commit)
            soff = Repositext::Subtitle::OperationsForFile.new(
              content_at_file_from,
              {
                file_path: content_at_file_from.repo_relative_path,
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

        # Hook for subclasses to modify compute_st_ops_attrs
        # @param compute_st_ops_attrs [Hash{Symbol => Object}]
        # @param context [Hash{Symbol => Object}]
        # @return [Hash] copy of original hash with possible modifications.
        def refine_compute_st_ops_attrs(compute_st_ops_attrs, context)
          # No modifications here. Override in subclasses.
          compute_st_ops_attrs
        end

      end
    end
  end
end
