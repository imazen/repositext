class Repositext
  class Process
    class Fix
      # Specifies validation modes according to validator_exception_settings for files
      # of content_type. Will create missing data.json files. Will not modify
      # existing settings for :validation_mode (reports them instead)
      class SpecifyValidatorExceptions

        # @param content_type [Repositext::ContentType]
        # @param validator_exception_settings [Hash<Hash>] with setting as key
        #   and another Hash as value (datecode+piid as key and validation mode as val)
        def self.fix(content_type, validator_exception_settings)
          created = []
          added = []
          exists_already = []
          wont_update = []

          language = content_type.language

          validator_exception_settings.each do |setting_name, file_validation_modes|
            file_validation_modes.each do |(datecode_and_piid, validation_mode)|
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
              if(ex_s = settings[setting_name])
                # Setting exists
                if ex_s == validation_mode
                  # Has correct setting
                  exists_already << data_json_path
                else
                  # Has different setting
                  wont_update << data_json_path
                end
              else
                # Setting does not exist, add it
                djf.update_settings!(setting_name => validation_mode)
                if created_this_file
                  created << data_json_path
                else
                  added << data_json_path
                end
              end
            end
          end

          puts "Summary for #{ language.name }:".color(:blue)
          puts "  created:"
          created.each { |e| puts "    * #{ e }"}
          puts "  added:"
          added.each { |e| puts "    * #{ e }"}
          puts "  exists_already:"
          exists_already.each { |e| puts "    * #{ e }"}
          puts("  wont_update:".color(:red))
          wont_update.each { |e| puts("    * #{ e }".color(:red)) }

          true
        end

      end
    end
  end
end
