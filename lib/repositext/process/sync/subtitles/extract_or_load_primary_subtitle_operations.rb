# encoding UTF-8
class Repositext
  class Process
    class Sync
      class Subtitles
        module ExtractOrLoadPrimarySubtitleOperations

          extend ActiveSupport::Concern

          # Checks if subtitle operations for boundary git commits have been
          # extracted already, if so uses them. Otherwise extracts them.
          def extract_or_load_primary_subtitle_operations
            st_ops_dir = File.join(@repository.base_dir, 'subtitle_operations')
            existing_st_ops_file_path = Dir.glob(File.join(st_ops_dir, "st-ops-*-#{ from_to_git_commit_marker }.json")).first
            st_ops_path = existing_st_ops_file_path || extract_and_store_primary_subtitle_operations
            json_with_temp_stids_replaced = replace_temp_with_persistent_stids!(
              File.read(st_ops_path),
              @stids_inventory_file
            )
            Subtitle::OperationsForRepository.from_json(
              json_with_temp_stids_replaced,
              @content_type.language,
              @repository.base_dir
            )
          end

        private

          # Computes the next sequence number for subtitle_operations files
          # based on the highest number present in subtitle_operations_dir
          # @param subtitle_operations_dir [String]
          # @return [String] with 5 digits
          def compute_next_st_ops_file_sequence_number(subtitle_operations_dir)
            existing_st_ops_file_names = Dir.glob(
              File.join(subtitle_operations_dir, "st-ops-*.json")
            )
            return '00001'  if existing_st_ops_file_names.empty?
            highest = existing_st_ops_file_names.sort.last
            # Extract serial number from st-ops-00010-5cbeee-to-75c444.json
            number = highest.match(/st-ops-([\d]{5})-.*\.json/)[1]
            raise "No matching filename found: #{ highest.inspect }"  if number.nil?
            number.succ
          end

          # Extracts subtitle operations for entire repo between two git commits.
          # @return [String] the name of the file operations are stored in
          def extract_and_store_primary_subtitle_operations
            subtitle_ops = Repositext::Process::Compute::SubtitleOperationsForRepository.new(
              @content_type,
              @from_git_commit,
              @to_git_commit,
              @file_list
            ).compute
            st_ops_path = File.join(
              @config.base_dir(:subtitle_operations_dir),
              [
                'st-ops-',
                compute_next_st_ops_file_sequence_number(@config.base_dir(:subtitle_operations_dir)),
                '-',
                from_to_git_commit_marker,
                '.json'
              ].join
            )
            puts " - Writing JSON file to #{ st_ops_path }"
            File.open(st_ops_path, 'w') { |f|
              f.write(subtitle_ops.to_json.to_s)
            }
            st_ops_path
          end

          # Returns the marker to be used in the file name for fromGitCommit
          # and toGitCommit
          def from_to_git_commit_marker
            [
              @from_git_commit.first(6),
              '-to-',
              @to_git_commit.first(6),
            ].join
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
