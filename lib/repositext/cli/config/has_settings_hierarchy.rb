class Repositext
  class Cli
    class Config
      module HasSettingsHierarchy

        # @param rtfile_path [String] absolute path to content_type level Rtfile
        # @return [Hash] with entries for all required execution_contexts.
        def compute_required_settings_hierarchy(rtfile_path)
          rsh = hierarchy_levels.inject({}) { |m,e| m[e] = {}; m }
          compute_required_setting_file_candidates(rtfile_path).each { |attrs|
            rsh[attrs['level']][attrs['identifier']] ||= { 'settings' => {} }
            attrs['files'].each { |file_candidate|
              if File.exists?(file_candidate)
                rsh[attrs['level']][attrs['identifier']]['settings'].merge!(
                  load_settings(file_candidate)
                )
              end
            }
          }
          rsh
        end

        # Traverses the settings hierarchy to compute the effective settings
        # for the given execution context.
        # Looks at @settings_hierarchy to find the most specific value for any
        # given setting, and looks at #execution_context to determine how far
        # down it has to go in the levels of specificity.
        def compute_effective_settings
          execution_context.inject({}) { |m,(level, identifier)|
            level_attrs = @settings_hierarchy[level]
            next  if level_attrs.nil?
            identifier_attrs = level_attrs[identifier]
            next  if identifier_attrs.nil?
            context_settings = identifier_attrs['settings']
            next  if context_settings.nil?
            context_settings.each { |key, val|
              m[key] = val
            }
            m
          }
        end

        # Updates the settings hierarchy's file level for the given data.json file
        # @param data_json_file_path [String] path to a file level data.json file
        def update_for_file(data_json_file_path)
          # Update file_level_identifier so that correct execution context is used.
          @file_level_identifier = data_json_file_path
          if File.exists?(data_json_file_path)
            # Assign settings from data.json file
            file_level_settings = load_settings(data_json_file_path)
            @settings_hierarchy['file'][@file_level_identifier] = { 'settings' => file_level_settings }
          else
            # Assign settings to empty hash.
            @settings_hierarchy['file'][@file_level_identifier] = { 'settings' => {} }
          end
          # Re-compute effective settings
          @effective_settings = compute_effective_settings
          true
        end

        # Returns a list of hierarchy levels from general to specific
        def hierarchy_levels
          required_hierarchy_levels + optional_hierarchy_levels
        end

        def required_hierarchy_levels
          %w(
            repositext
            repository
            content_type
          )
        end

        def optional_hierarchy_levels
          %w(
            file
            subtitle
          )
        end

        def execution_context
          required_execution_context + optional_execution_context
        end

        # [
        #   ['repositext', 'repositext'],
        #   ['repository', 'english'],
        #   ['content_type', 'ct-general'],
        # ]
        def required_execution_context
          required_hierarchy_levels.map { |level|
            next nil  if @settings_hierarchy[level].nil?
            candidates = @settings_hierarchy[level].keys
            if candidates.length != 1
              raise "Ambiguous identifiers at level #{ level }; #{ candidates.inspect }"
            end
            [level, candidates.first]
          }.compact
        end

        # [
        #   ['file', <relative path from content_type level>], (optional)
        #   ['subtitle', '123456'], (optional)
        # ]
        def optional_execution_context
          oec = []
          if !@file_level_identifier.nil?
            oec << ['file', @file_level_identifier]
            if !@subtitle_level_identifier.nil?
              oec << ['subtitle', @subtitle_level_identifier]
            end
          end
          oec
        end

        # Computes paths for all possible required setting files.
        # Evaluates Rtfiles after required JSON files to give them override powers.
        # @param rtfile_path [String] absolute path to content_type level Rtfile
        # @return [Array<Hash>]
        def compute_required_setting_file_candidates(rtfile_path)
          # Make sure rtfile_path is what we expect it to be:
          # * Must end with "/Rtfile"
          # * Must contain Rtfile only once!
          if rtfile_path !~ /\/Rtfile\z/ || 1 != rtfile_path.scan('Rtfile').count
            raise ArgumentError.new("Invalid rtfile_path: #{ rtfile_path.inspect }")
          end
          path_segments = rtfile_path.split('/')
          repositext_root = path_segments[0..-4]
          repository_root = path_segments[0..-3]
          content_type_root = path_segments[0..-2]
          [
            {
              'level' => 'repositext',
              'identifier' => 'repositext',
              'files' => [
                File.join(repositext_root, 'data.json'),
                File.join(repositext_root, 'Rtfile'),
              ]
            },
            {
              'level' => 'repository',
              'identifier' => repository_root.last,
              'files' => [
                File.join(repository_root, 'data.json'),
                File.join(repository_root, 'Rtfile'),
              ]
            },
            {
              'level' => 'content_type',
              'identifier' => content_type_root.last,
              'files' => [
                File.join(content_type_root, 'data.json'),
                File.join(content_type_root, 'Rtfile'),
              ]
            },
          ]
        end

        # Loads settings from the settings file at setting_file_path.
        # @param setting_file_path [String] to an Rtfile or a data.json file.
        def load_settings(setting_file_path)
          case setting_file_path
          when /data\.json$/
            load_settings_from_json_file(setting_file_path)
          when /Rtfile$/
            load_settings_from_rtfile(setting_file_path)
          else
            raise "Handle this: #{ setting_file_path.inspect }"
          end
        end

        def load_settings_from_json_file(json_data_file_path)
          FromJsonDataFile.new(json_data_file_path).load
        end

        def load_settings_from_rtfile(rtfile_path)
          FromRtfile.new(rtfile_path).load
        end

      end
    end
  end
end
