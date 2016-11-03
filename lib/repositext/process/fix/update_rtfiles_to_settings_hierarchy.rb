class Repositext
  class Process
    class Fix
      # Updates Rtfiles for settings hierarchy:
      # * Renames some setting names in Rtfile
      # * Moves some settings to repositext and repository data.json files
      class UpdateRtfilesToSettingsHierarchy

        # @param old_config [Repositext::Cli::Config] based on Rtfile to be updated
        def self.fix(old_config)
          if old_config.base_dir(:content_type_dir)
            puts "     - has already been updated. Skipping."
            return true
          end

          rtfile_path = File.join(
            old_config.compute_base_dir(:rtfile_dir),
            'Rtfile'
          )
          data_file_paths = compute_data_file_paths(old_config, rtfile_path)

          # Rename rtfile settings so that we can use the after names
          old_rtfile_contents = File.read(rtfile_path)
          medium_rtfile_contents = rename_settings_in_rtfile(old_rtfile_contents)
          write_rtfile_contents(rtfile_path, medium_rtfile_contents)

          # Reload config with renamed settings
          new_config = Repositext::Cli::Config.new(rtfile_path)
          new_config.compute

          # Repositext level settings
          rtx_data_file_path = data_file_paths['repositext']
          rtx_lvl_settings = initialize_repositext_level_settings(
            new_config,
            rtx_data_file_path
          )
          write_rtx_lvl_settings(rtx_lvl_settings, rtx_data_file_path)

          # Repository level settings
          rpy_data_file_path = data_file_paths['repository']
          rpy_lvl_settings = initialize_repository_level_settings(
            new_config,
            rpy_data_file_path
          )
          write_rpy_lvl_settings(rpy_lvl_settings, rpy_data_file_path)

          # Rtfile
          old_rtfile_contents = File.read(rtfile_path)
          new_rtfile_contents = remove_rtfile_entries(old_rtfile_contents)
          new_rtfile_contents = update_data_base_dir(new_rtfile_contents)
          write_rtfile_contents(rtfile_path, new_rtfile_contents)
          true
        end

        # @param data_file_path [String] path to where data.json file is expected to be
        # @return [Hash] data structure that represents settings at the given level
        def self.initialize_repositext_level_settings(config, data_file_path)
          settings = if(File.exists?(data_file_path))
            # Check if file already exists. If so load initial settings from it
            JSON.load(File.read(data_file_path))['settings'] || {}
          else
            # otherwise start with empty hash
            {}
          end
          apply_settings!(config, settings_to_be_moved_to_repositext_level, settings)
          { 'settings' => settings }
        end

        def self.write_rtx_lvl_settings(new_settings, data_file_path)
          new_settings_json = JSON.generate(new_settings, json_opts)
          File.write(data_file_path, new_settings_json)
        end

        # @param data_file_path [String] path to where data.json file is expected to be
        # @return [Hash] data structure that represents settings at the given level
        def self.initialize_repository_level_settings(config, data_file_path)
          settings = if(File.exists?(data_file_path))
            # Check if file already exists. If so load initial settings from it
            JSON.load(File.read(data_file_path))['settings'] || {}
          else
            # otherwise start with empty hash
            {}
          end
          apply_settings!(config, settings_to_be_moved_to_repository_level, settings)
          { 'settings' => settings }
        end

        def self.write_rpy_lvl_settings(new_settings, data_file_path)
          new_settings_json = JSON.generate(new_settings, json_opts)
          File.write(data_file_path, new_settings_json)
        end

        def self.remove_rtfile_entries(old_rtfile_contents)
          r = old_rtfile_contents.dup
          # Remove settings that were moved to the repositext and repository levels
          remove_settings_from_rtfile(r, settings_to_be_moved_to_repositext_level)
          remove_settings_from_rtfile(r, settings_to_be_moved_to_repository_level)
          r
        end

        def self.write_rtfile_contents(rtfile_path, new_rtfile_contents)
          File.write(rtfile_path, new_rtfile_contents)
        end

        # @return [Hash] with levels as keys and file_paths as values
        def self.compute_data_file_paths(config, rtfile_path)
          all_data_file_candidates = config.compute_required_setting_file_candidates(
            rtfile_path
          )
          all_data_file_candidates.inject(
            { 'content_type' => rtfile_path }
          ) { |m,e|
            if 'repositext' == e['level']
              m['repositext'] = e['files'].detect { |f| f.index('data.json') }
            elsif 'repository' == e['level']
              m['repository'] = e['files'].detect { |f| f.index('data.json') }
            end
            m
          }
        end

        def self.rename_settings_in_rtfile(old_rtfile_contents)
          r = old_rtfile_contents.dup
          # Rename some settings
          r.sub!(/(?<=^setting :)relative_path_to_primary_repo/, 'relative_path_to_primary_content_type')
          r.sub!(/(?<=^base_dir :)rtfile_dir/, 'content_type_dir')
          r
        end

        def self.settings_to_be_moved_to_repositext_level
          %w[
            file_extension_at_extension
            file_extension_csv_extension
            file_extension_docx_extension
            file_extension_html_extension
            file_extension_icml_extension
            file_extension_idml_extension
            file_extension_json_extension
            file_extension_pdf_extension
            file_extension_pt_extension
            file_extension_repositext_extensions
            file_extension_txt_extension
            file_extension_xml_extension
            file_selector_all_files
            file_selector_validation_report_file
            kramdown_converter_method_to_at
            kramdown_converter_method_to_docx
            kramdown_converter_method_to_html_doc
            kramdown_converter_method_to_icml
            kramdown_converter_method_to_plain_text
            kramdown_converter_method_to_subtitle
            kramdown_converter_method_to_subtitle_tagging
            kramdown_parser_docx
            kramdown_parser_docx_validation
            kramdown_parser_folio_xml
            kramdown_parser_idml
            kramdown_parser_idml_validation
            kramdown_parser_kramdown
            kramdown_parser_kramdown_validation
          ]
        end

        def self.settings_to_be_moved_to_repository_level
          %w[
            folio_import_strategy
            is_primary_repo
            language_code_2_chars
            language_code_3_chars
            primary_repo_lang_code
            first_eagle_override
            font_leading_override
            font_name_override
            font_size_override
            pdf_export_version_control_page
            relative_path_to_primary_content_type
          ]
        end

        # Changes settings in place
        # @param config [Config] that has settings to be transferred
        # @param setting_names [Array<String>]
        # @param settings [Hash]
        def self.apply_settings!(config, setting_names, settings)
          setting_names.each { |setting_name|
            case setting_name
            when /^file_extension_/
              file_extension_name = setting_name.sub('file_extension_', '')
              if !(v = config.file_extension(file_extension_name)).nil?
                settings[setting_name] = v
              end
            when /^file_selector_/
              file_selector_name = setting_name.sub('file_selector_', '')
              if !(v = config.file_selector(file_selector_name)).nil?
                settings[setting_name] = v
              end
            when /^kramdown_converter_method_/
              kramdown_converter_method_name = setting_name.sub('kramdown_converter_method_', '')
              if !(v = config.kramdown_converter_method(kramdown_converter_method_name)).nil?
                settings[setting_name] = v
              end
            when /^kramdown_parser_/
              kramdown_parser_name = setting_name.sub('kramdown_parser_', '')
              # Convert parser class to its name as string so it can be serialized
              # in JSON data file.
              if !(v = config.kramdown_parser(kramdown_parser_name).to_s).nil?
                settings[setting_name] = v
              end
            else
              if !(v = config.setting(setting_name)).nil?
                settings[setting_name] = v
              end
            end
          }
        end

        def self.json_opts
          {
            indent: '  ',
            space: '',
            space_before: '',
            object_nl: "\n",
            array_nl: "\n",
            allow_nan: false,
            max_nesting: 100,
          }
        end

        # Modifies original_string in place
        def self.remove_settings_from_rtfile(original_string, setting_names)
          setting_names.each do |setting_name|
            case setting_name
            when /^file_extension_/
              file_extension_name = setting_name.sub('file_extension_', '')
              original_string.sub!(/^file_extension :#{ file_extension_name }[^\n]+\n/, '')
            when /^file_selector_/
              file_selector_name = setting_name.sub('file_selector_', '')
              original_string.sub!(/^file_selector :#{ file_selector_name }[^\n]+\n/, '')
            when /^kramdown_converter_method_/
              kramdown_converter_method_name = setting_name.sub('kramdown_converter_method_', '')
              original_string.sub!(/^kramdown_converter_method :#{ kramdown_converter_method_name }[^\n]+\n/, '')
            when /^kramdown_parser_/
              kramdown_parser_name = setting_name.sub('kramdown_parser_', '')
              original_string.sub!(/^kramdown_parser :#{ kramdown_parser_name }[^\n]+\n/, '')
            else
              original_string.sub!(/^setting :#{ setting_name }[^\n]+\n/, '')
            end
          end
        end

        def self.update_data_base_dir(rtfile_contents)
          rtfile_contents.gsub(
            %(base_dir :data_dir, File.expand_path("data/", File.dirname(__FILE__))\n),
            %(base_dir :data_dir, File.expand_path("../data/", File.dirname(__FILE__))\n),
          )
        end

      end
    end
  end
end
