# encoding UTF-8
class Repositext
  class Process
    class Sync
      class Subtitles
        # This namespace provides methods related to finalizing a subtitle sync.
        module FinalizeSyncOperation

          extend ActiveSupport::Concern

          # Finalizes the subtitles sync operation
          def finalize_sync_operation
            puts "   - Transferred the following #{ @st_ops_cache_file.keys.count } st_ops versions to foreign repos:"
            @st_ops_cache_file.keys.each { |from_git_commit, to_git_commit|
              puts "     - #{ from_git_commit } to #{ to_git_commit }"
            }
            if @successful_files_with_st_ops.any?
              puts "   - The following #{ @successful_files_with_st_ops.count } files with st operations were synced successfully:".color(:green)
              @successful_files_with_st_ops.each { |file_path| puts "     - #{ file_path }" }
            else
              puts "   - No files with st operations were synced successfully".color(:red)
            end
            if @successful_files_with_autosplit.any?
              puts "   - The following #{ @successful_files_with_autosplit.count } files with autosplit were synced successfully:".color(:green)
              @successful_files_with_autosplit.each { |file_path| puts "     - #{ file_path }" }
            else
              puts "   - No files with autosplit were synced successfully".color(:red)
            end
            if @successful_files_without_st_ops.any?
              puts "   - The following #{ @successful_files_without_st_ops.count } files without st operations were synced successfully:".color(:green)
              @successful_files_without_st_ops.each { |file_path| puts "     - #{ file_path }" }
            else
              puts "   - No files without st operations were synced successfully".color(:red)
            end
            if @unprocessable_files.any?
              puts "   - The following #{ @unprocessable_files.count } files could not be synced:".color(:red)
              @unprocessable_files.each { |f_attrs|
                print "     - #{ f_attrs[:file].repo_relative_path(true) }: ".ljust(52).color(:red)
                puts "#{ f_attrs[:message] }".color(:red)
              }
            else
              puts "   - All file syncs were successful!".color(:green)
            end
            if @files_with_autosplit_exceptions.any?
              puts "   - The following #{ @files_with_autosplit_exceptions.count } files raised an exception during autosplit:".color(:red)
              @files_with_autosplit_exceptions.each { |f_attrs|
                print "     - #{ f_attrs[:file].repo_relative_path(true) }: ".ljust(52).color(:red)
                puts "#{ f_attrs[:message] }".color(:red)
              }
            else
              puts "   - No files raised exceptions during autosplit".color(:green)
            end
            if @files_with_subtitle_count_mismatch.any?
              puts "   - The following #{ @files_with_subtitle_count_mismatch.count } files were synced, however their subtitle counts don't match:".color(:red)
              @files_with_subtitle_count_mismatch.each { |f_attrs|
                print "     - #{ f_attrs[:file].repo_relative_path(true) }: ".ljust(52).color(:red)
                puts "#{ f_attrs[:message] }".color(:red)
              }
            else
              puts "   - All synced files have matching subtitle counts.".color(:green)
            end
            true
          end

        end
      end
    end
  end
end
