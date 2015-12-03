# encoding UTF-8
class Repositext
  class Process
    class Sync

      # Manages symlinks for subtitle marker csv files.
      #
      class SubtitleMarkerCsvFileSymlinks

        # Initialize a new file sync process
        # @param foreign_content_at_file [RFile]
        # @param requires_symlink [Boolean]
        def initialize(foreign_content_at_file, requires_symlink)
          raise(ArgumentError.new("Invalid foreign_content_at_file: #{ foreign_content_at_file.inspect }"))  unless foreign_content_at_file.is_a?(RFile)
          @foreign_content_at_file = foreign_content_at_file
          @requires_symlink = requires_symlink
        end

        # Synchronizes STM CSV file symlink for @foreign_content_at_file.
        # Returns outcome with description of operation as String or nil for no-op
        # @return [String, Nil]
        def sync
          foreign_subtitle_markers_csv_filename = @foreign_content_at_file.corresponding_subtitle_markers_csv_filename
          outcome_attrs = if @requires_symlink
            # Symlink is required
            if File.exist?(foreign_subtitle_markers_csv_filename)
              # Already exists, nothing to do
              [true, nil]
            else
              # Doesn't exist, create it
              FileUtils.cd(@foreign_content_at_file.dir)
              FileUtils.ln_s(
                RFile::Text.relative_path_to_corresponding_primary_file(
                  foreign_subtitle_markers_csv_filename,
                  @foreign_content_at_file.repository
                ),
                File.basename(foreign_subtitle_markers_csv_filename),
              )
              [true, "Created missing symlink #{ File.basename(foreign_subtitle_markers_csv_filename).inspect }"]
            end
          else
            # Symlink is NOT required
            if File.exist?(foreign_subtitle_markers_csv_filename)
              # Already exists, delete it
              FileUtils.rm(foreign_subtitle_markers_csv_filename)
              [true, "Deleted existing symlink #{ File.basename(foreign_subtitle_markers_csv_filename).inspect }"]
            else
              # Doesn't exist, nothing to do
              [true, nil]
            end
          end
          Outcome.new(*outcome_attrs)
        end

      end
    end
  end
end
