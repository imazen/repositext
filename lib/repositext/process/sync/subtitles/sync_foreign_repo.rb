# encoding UTF-8
class Repositext
  class Process
    class Sync
      class Subtitles
        # This namespace provides methods related to syncing subtitles for a foreign repo.
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
              next  if(ct_base_dir = content_type.config_base_dir(:content_dir)).nil?
              # Load ct specific config
              ct_config = content_type.config
              # Iterate over all content_at files.
              Dir.glob(
                File.join(ct_base_dir, '**/*.at')
              ).each do |content_at_file_path|
                content_at_file = RFile::ContentAt.new(
                  File.read(content_at_file_path),
                  content_type.language,
                  content_at_file_path,
                  content_type
                )
                # Reload settings for file
                ct_config.update_for_file(content_at_file_path.gsub(/\.at\z/, '.data.json'))
                # Load file level data
                file_level_data = content_at_file.read_file_level_data

                # Sync files that
                # * participate in st-sync,
                # * require an st_sync, and
                # * don't have a pending subtitle import.
                st_sync_required = (
                  ct_config.setting(:st_sync_active) &&
                  file_level_data['st_sync_commit'] != @to_git_commit
                )
                has_pending_subtitle_import = '' != file_level_data['exported_subtitles_at_st_sync_commit'].to_s
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
