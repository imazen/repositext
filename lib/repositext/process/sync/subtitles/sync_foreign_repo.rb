# encoding UTF-8
class Repositext
  class Process
    class Sync
      class Subtitles
        module SyncForeignRepo

          extend ActiveSupport::Concern

          # Syncronizes subtitle operations for the foreign_repository
          # @param foreign_repository [Repository]
          def sync_foreign_repo(foreign_repository)
            compute_foreign_files_to_sync(
              foreign_repository
            ).each do |foreign_content_at_file|
              sync_foreign_file(foreign_content_at_file)
            end
          end

        private

          # @param foreign_repository [Repository]
          # @return [Array<RFile::ContentAt>]
          def compute_foreign_files_to_sync(foreign_repository)
            fts = []
            # Iterate over all content types
            ContentType.all(foreign_repository).each do |content_type|
              # Iterate over all content_at files.
              Dir.glob(
                File.join(content_type.config_base_dir(:content_dir), '**/*.at')
              ).each do |content_at_file_path|
                content_at_file = RFile::ContentAt.new(
                  File.read(content_at_file_path),
                  content_type.language,
                  content_at_file_path,
                  content_type
                )
                file_level_data = content_at_file.read_file_level_data

                # Sync files that require an st_sync and that don't have a pending
                # subtitle import.
                st_sync_required = file_level_data['st_sync_commit'] != @to_git_commit
                has_pending_subtitle_import = '' != file_level_data['exported_at_st_sync_commit'].to_s
                if st_sync_required && !has_pending_subtitle_import
                  fts << content_at_file
                end
              end
            end
            fts
          end
        end
      end
    end
  end
end
