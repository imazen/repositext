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
            puts "   - Transferred the following st_ops to foreign repos:"
            @st_ops_cache_file.keys.each { |from_git_commit, to_git_commit|
              puts "     - #{ from_git_commit } to #{ to_git_commit }"
            }
            if @unprocessable_files.any?
              puts "   - The following #{ @unprocessable_files.count } files could not be synced:".color(:red)
              @unprocessable_files.each { |f_attrs|
                print "     - #{ f_attrs[:file].repo_relative_path(true) }:".ljust(52).color(:red)
                puts "#{ f_attrs[:message] }".color(:red)
              }
            else
              puts "   - All file syncs were successful!".color(:green)
            end
            true
          end

        end
      end
    end
  end
end
