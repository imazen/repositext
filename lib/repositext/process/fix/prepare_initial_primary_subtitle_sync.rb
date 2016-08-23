class Repositext
  class Process
    class Fix

      # Prepares primary repo for the first st_sync:
      #  * Copies time slices from current STM CSV files to subtitle_import dir
      #    This will guarantee that every content AT file has a corresponding
      #    subtitle import file with up-to-date time slices.
      #  * Sets the `last_st_sync_commit_for_this_file` attribute for every
      #    content AT file to the baseline from commit (st_sync_commit recorded
      #    in the primary repo's data.json file).
      class PrepareInitialPrimarySubtitleSync

        # Initialize a new fix process
        # @param options [Hash] with stringified keys
        # @option options [Config] 'config'
        # @option options [Array<String>] 'file_list' can be used at command
        #                                 line via file-selector to limit which
        #                                 files should be synced.
        # @option options [String, Nil] 'from-commit', optional, defaults to previous `to-commit`
        # @option options [Repository] 'primary_repository' the primary repo
        # @option options [IO] stids_inventory_file
        # @option options [String, Nil] 'to-commit', optional, defaults to most recent local git commit
        def initialize(options)
          @config = options['config']
          @file_list = options['file_list']
          @from_git_commit = options['from-commit']
          @primary_repository = options['primary_repository']
          @processed_files_count = 0
        end

        def sync
          puts
          puts "Preparing primary files for initial primary subtitle sync".color(:blue)
          puts

          puts " - Load baseline 'from_git_commit' from primary repo's data.json file:".color(:blue)
          @from_git_commit = @primary_repository.read_repo_level_data['st_sync_commit']
          puts "   - #{ @from_git_commit.inspect }"

          puts " - Process primary files:".color(:blue)
          # Pick any content_type, doesn't matter which one
          content_type = ContentType.all(@primary_repository).first
          @file_list.each do |content_at_file_path|
            content_at_file = RFile::ContentAt.new(
              File.read(content_at_file_path),
              content_type.language,
              content_at_file_path,
              content_type
            )
            puts "   - #{ content_at_file.repo_relative_path }"
            process_primary_file(content_at_file)
          end

          puts " - Finalize operation".color(:blue)
          finalize_operation
        end

      private

        def process_primary_file(content_at_file)
          subtitle_import_markers_filename = content_at_file.corresponding_subtitle_import_markers_filename
          puts "     - copy time slices from STM CSV file to #{ subtitle_import_markers_filename }"

          # Load time slices from STM CSV file
          stm_csv_file = content_at_file.corresponding_subtitle_markers_csv_file
          time_slices = []
          stm_csv_time_slices = stm_csv_file.each_row { |e|
            time_slices << [e['relativeMS'], e['samples']]
          }

          # Write time slices to st_imp_filename
          # Convert to CSV
          csv_string = CSV.generate(col_sep: "\t") do |csv|
            csv << Repositext::Utils::SubtitleMarkTools.csv_headers.first(2)
            time_slices.each do |row|
              csv << row
            end
          end
          File.write(subtitle_import_markers_filename, csv_string)

          puts "     - set 'last_st_sync_commit_for_this_file'"
          @processed_files_count += 1
        end

        # Computes new subtitle char_lengths for all subtitles in content_at.
        # @param content_at_file [RFile::ContentAt] needs to be at toGitCommit
        # @return [Array<Integer>]
        def compute_new_char_lengths(content_at_file)
          Repositext::Utils::SubtitleMarkTools.extract_captions(
            content_at_file.contents
          ).map { |e| e[:char_length] }
        end

        def finalize_operation
          puts "   - Processed #{ @processed_files_count } primary files.".color(:green)
        end

      end
    end
  end
end
