# encoding UTF-8
class Repositext
  class Process
    class Sync
      class Subtitles
        module ExtractOrLoadPrimarySubtitleOperations

          extend ActiveSupport::Concern

          # Checks if subtitle operations for boundary git commits have been
          # extracted already, if so uses them. Otherwise extracts them (unless
          # it expects_st_ops_file_to_exist)
          # @param expects_st_ops_file_to_exist [Boolean, optional] set to true
          #        if you expect the st-ops file to exist and you don't want to
          #        extract operations but raise an exception if it doesn't.
          # @return [Array<Subtitle::OperationsForRepository, Boolean>] a tuple
          #        of the operations and a flag that indicates whether a new
          #        st-ops file was created, or an existing one was used.
          def extract_or_load_primary_subtitle_operations(expects_st_ops_file_to_exist=false)
            existing_st_ops_file_path = Subtitle::OperationsFile.detect_st_ops_file_path(
              @config.base_dir(:subtitle_operations_dir),
              @from_git_commit,
              @to_git_commit
            )
            created_new_st_ops_file = nil
            if existing_st_ops_file_path.nil? && expects_st_ops_file_to_exist
              raise([
                "Expected st ops file for",
                Subtitle::OperationsFile.compute_from_to_git_commit_marker(
                  @from_git_commit, @to_git_commit
                ),
                "to exist!"
              ].join(' '))
            end
            st_ops_file_path = if existing_st_ops_file_path
              puts " - Using existing st-ops file at #{ existing_st_ops_file_path }".color(:blue)
              created_new_st_ops_file = false
              existing_st_ops_file_path
            else
              puts " - Computing st-ops from #{ @from_git_commit.first(6) } to #{ @to_git_commit.first(6) }".color(:blue)
              created_new_st_ops_file = true
              extract_and_store_primary_subtitle_operations
            end

            json_with_persistent_stids = File.read(st_ops_file_path)
            st_ops = Subtitle::OperationsForRepository.from_json(
              json_with_persistent_stids,
              @repository.base_dir
            )
            [st_ops, created_new_st_ops_file]
          end

        private

          # Extracts subtitle operations for entire repo between two git commits.
          # @return [String] the name of the file operations are stored in
          def extract_and_store_primary_subtitle_operations
            subtitle_ops = []
            # Pick any content_type, doesn't matter which one
            content_type = ContentType.all(@repository).first
            subtitle_ops = Repositext::Process::Compute::SubtitleOperationsForRepository.new(
              content_type,
              @from_git_commit,
              @to_git_commit,
              @file_list
            ).compute
            st_ops_file_path = Subtitle::OperationsFile.compute_next_file_path(
              @config.base_dir(:subtitle_operations_dir),
              @from_git_commit,
              @to_git_commit
            )
            puts " - Writing st-ops file to #{ st_ops_file_path }".color(:blue)
            json_with_temp_stids = subtitle_ops.to_json.to_s
            puts "   - Assigning new subtitle ids"
            json_with_persistent_stids = replace_temp_with_persistent_stids!(
              json_with_temp_stids,
              @stids_inventory_file
            )
            puts "   - Writing JSON file"
            persist_st_ops!(st_ops_file_path, json_with_persistent_stids)
            st_ops_file_path
          end

          # Persists st-ops to file
          # @param st_ops_file_path [String]
          # @param st_ops_json [String]
          def persist_st_ops!(st_ops_file_path, st_ops_json)
            File.open(st_ops_file_path, 'w') { |f| f.write(st_ops_json) }
          end

          # Replaces all temp stids with persistent ones in json string
          # @param json_string [String] the original json string with temp stids
          # @param stids_inventory_file [IO]
          # @return [String] a copy of json_string with all temp stids replaced
          def replace_temp_with_persistent_stids!(json_string, stids_inventory_file)
            new_json_string = json_string.dup
            # Find all temp stids: "stid": "tmp-1867814+1"
            all_temp_stids = new_json_string.scan(/(?<="stid": ")tmp-[\d\+]+(?=",\n)/).uniq
            # Generate new stids
            new_stids = Repositext::Subtitle::IdGenerator.new(
              stids_inventory_file
            ).generate(
              all_temp_stids.length
            ).shuffle

            # Replace temp stids
            all_temp_stids.each { |temp_stid|
              new_stid = new_stids.shift
              raise "Handle this: #{ new_subtitles.inspect }"  if new_stid.nil?
              new_json_string.gsub!(temp_stid, new_stid)
            }
            new_json_string
          end

        end
      end
    end
  end
end
