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
            existing_st_ops_file_path = detect_expected_st_ops_file_path(
              st_ops_dir,
              from_to_git_commit_marker
            )
            st_ops_file_path = existing_st_ops_file_path || extract_and_store_primary_subtitle_operations
            json_with_persistent_stids = File.read(st_ops_file_path)
            Subtitle::OperationsForRepository.from_json(
              json_with_persistent_stids,
              @content_type.language,
              @repository.base_dir
            )
          end

        private

          # Detects if the st-ops file with the expected filename exists and
          # returns its complete path, or Nil otherwise.
          # @param st_ops_dir [String] path to directory that contains all st-ops files
          # @param from_to_commit_id [String] the unique marker based on from_commit and to_commit
          # @return [String, Nil] path to expected st-ops file if it exists, Nil otherwise.
          def detect_expected_st_ops_file_path(st_ops_dir, from_to_commit_id)
            Dir.glob(File.join(st_ops_dir, "st-ops-*-#{ from_to_commit_id }.json")).first
          end

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
            st_ops_file_path = compute_next_st_ops_file_path(
              @config.base_dir(:subtitle_operations_dir),
              compute_next_st_ops_file_sequence_number(@config.base_dir(:subtitle_operations_dir)),
              from_to_git_commit_marker
            )
            puts " - Writing JSON file to #{ st_ops_file_path }"
            json_with_temp_stids = subtitle_ops.to_json.to_s
            json_with_persistent_stids = replace_temp_with_persistent_stids!(
              json_with_temp_stids,
              @stids_inventory_file
            )
            persist_st_ops!(st_ops_file_path, json_with_persistent_stids)
            st_ops_file_path
          end

          # Computes the path for the next st-ops file
          # @param st_ops_dir [String] path to directory that contains all st-ops files
          # @param next_sequence_number [String]
          # @param from_to_commit_id [String] the unique marker based on from_commit and to_commit
          def compute_next_st_ops_file_path(st_ops_dir, next_sequence_number, from_to_commit_id)
            File.join(
              st_ops_dir,
              [
                'st-ops-',
                next_sequence_number,
                '-',
                from_to_commit_id,
                '.json'
              ].join
            )
          end

          # Persists st-ops to file
          # @param st_ops_file_path [String]
          # @param st_ops_json [String]
          def persist_st_ops!(st_ops_file_path, st_ops_json)
            File.open(st_ops_path, 'w') { |f| f.write(st_ops_json) }
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
