class Repositext
  class Process
    class Fix
      # Specifies validator_exceptions according to validator_exception_settings
      # for files of content_type. Will create missing data.json files. Will
      # update existing files.
      # NOTE: This script will not remove existing settings for files that
      # don't require validator_exceptions any more. They have to be removed
      # manually.
      class SpecifyValidatorExceptions

        # @param content_type [Repositext::ContentType]
        # @param validator_exception_settings [Hash<Hash>] with setting as key
        #   and another Hash as value (datecode+piid as key and validator exceptions as val)
        def self.fix(content_type, validator_exception_settings)
          added = []
          created_data_json_file = []
          identical = []
          updated = []

          language = content_type.language

          validator_exception_settings.each do |setting_name, files_list|
            files_list.each do |(datecode_and_piid, validator_exceptions)|
              created_this_file = false
              year = datecode_and_piid[/\A\d{2}/]
              data_json_path = File.join(
                content_type.base_dir,
                "content",
                year,
                "#{ language.code_3_chars }#{ datecode_and_piid }.data.json"
              )
              if !File.exist?(data_json_path)
                created_this_file = true
                RFile::DataJson.create_empty_data_json_file!(data_json_path)
              end

              djf = RFile::DataJson.new(
                File.read(data_json_path),
                language,
                data_json_path,
                content_type
              )
              settings = djf.read_settings
              update_settings = false

              if(ex_s = settings[setting_name])
                # Setting exists
                if ex_s == validator_exceptions
                  # Has correct setting
                  identical << data_json_path
                else
                  # Has different setting
                  updated << data_json_path
                  update_settings = true
                end
              else
                # Setting does not exist, add it
                update_settings = true
                if created_this_file
                  created_data_json_file << data_json_path
                else
                  added << data_json_path
                end
              end

              if update_settings
                djf.update_settings!(setting_name => validator_exceptions)
              end
            end
          end

          puts "Summary for #{ language.name }:".color(:blue)
          puts "  created_data_json_file:"
          created_data_json_file.each { |e| puts "    * #{ e }"}
          puts "  added:"
          added.each { |e| puts "    * #{ e }"}
          puts "  identical:"
          identical.each { |e| puts "    * #{ e }"}
          puts "  updated:"
          updated.each { |e| puts "    * #{ e }" }

          true
        end

      end
    end
  end
end
