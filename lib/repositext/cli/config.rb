class Repositext
  class Cli

    # Manages configuration of Cli instance (via Rtfile and *.data.json files)
    # Config is loaded from a number of places (in hierarchical order).
    class Config

      include HasSettingsHierarchy

      BASE_DIR_NAME_REGEX = /\A\w+_dir\z/
      FILE_EXTENSION_NAME_REGEX = /\A\w+_extensions?\z/
      FILE_SELECTOR_NAME_REGEX = /\A\w+_files?\z/

      # @param rtfile_path [String] absolute path to the rtfile, including filename
      def initialize(rtfile_path)
        @rtfile_path = rtfile_path
        @effective_settings = {}
        @settings_hierarchy = {}
      end

      # Checks from repositext level down to content_type level for JSON data
      # files and Rtfiles to collect settings hierarchy and computes effective
      # settings.
      # @return self
      def compute
        @settings_hierarchy = compute_required_settings_hierarchy(@rtfile_path)
        @effective_settings = compute_effective_settings
        self
      end

      # Retrieve a base dir
      # @param name [String, Symbol]
      def base_dir(name)
        name = name.to_s
        if name !~ BASE_DIR_NAME_REGEX
          raise ArgumentError.new("A base dir name must match this regex: #{ BASE_DIR_NAME_REGEX.inspect }")
        end
        # Return nil if key doesn't exist
        return nil  if (val = @effective_settings["base_dir_#{ name }"]).nil?
        # Guarantee trailing slash
        File.join(val, '')
      end

      # Retrieve a file extension
      # @param name [String, Symbol]
      def file_extension(name)
        name = name.to_s
        if name !~ FILE_EXTENSION_NAME_REGEX
          raise ArgumentError.new("A file pattern name must match this regex: #{ FILE_EXTENSION_NAME_REGEX.inspect }")
        end
        @effective_settings["file_extension_#{ name }"]
      end

      # Retrieve a file selector
      # @param name [String, Symbol]
      def file_selector(name)
        name = name.to_s
        if name !~ FILE_SELECTOR_NAME_REGEX
          raise ArgumentError.new("A file pattern name must match this regex: #{ FILE_SELECTOR_NAME_REGEX.inspect }")
        end
        @effective_settings["file_selector_#{ name }"]
      end

      # Retrieve a kramdown converter method
      # @param name [String, Symbol]
      def kramdown_converter_method(name, raise_on_unknown_key=true)
        key = "kramdown_converter_method_#{ name.to_s }"
        if raise_on_unknown_key && !@effective_settings.keys.include?(key)
          raise RtfileError.new("You requested an unknown key: #{ key.inspect }")
        end
        @effective_settings[key]
      end

      # Retrieve a kramdown parser
      # @param name [String, Symbol]
      def kramdown_parser(name, raise_on_unknown_key=true)
        key = "kramdown_parser_#{ name.to_s }"
        if raise_on_unknown_key && !@effective_settings.keys.include?(key)
          raise RtfileError.new("You requested an unknown key: #{ key.inspect }")
        end
        Object.const_get(@effective_settings[key])
      end

      # @param key [String, Symbol]
      # @param raise_on_unknown_key [Boolean, optional] defaults to true. Set to false for optional settings
      def setting(key, raise_on_unknown_key = true)
        key = key.to_s
        if raise_on_unknown_key && !@effective_settings.keys.include?(key)
          raise RtfileError.new("You requested an unknown key: #{ key.inspect }")
        end
        # NOTE: Avoid accidental changes to config values via destructive methods or '<<'!!
        @effective_settings[key].freeze
      end

      # Computes an absolute base_dir path from a_base_dir. First segment of file_spec.
      # Guaranteed to have a trailing slash.
      # (see #compute_glob_pattern)
      def compute_base_dir(a_base_dir)
        a_base_dir = a_base_dir.to_s.strip
        if a_base_dir =~ BASE_DIR_NAME_REGEX # e.g., 'content_dir'
          # Use named base_dir from Rtfile
          base_dir(a_base_dir)
        elsif '/' == a_base_dir[0]
          # Use absolute path as is, guarantee trailing slash
          a_base_dir.gsub(/(\/*)\z/, '') + '/'
        else
          raise(ArgumentError.new("Invalid base_dir given: #{ a_base_dir.inspect }"))
        end
      end

      # Computes a glob file pattern from a_file_extension. Third segment of file_spec.
      # Guaranteed to start with a period unless it's blank.
      # (see #compute_glob_pattern)
      def compute_file_extension(a_file_extension)
        a_file_extension = a_file_extension.to_s.strip
        if a_file_extension =~ FILE_EXTENSION_NAME_REGEX # e.g., 'at_extension'
          # Use named file_extension from Rtfile
          file_extension(a_file_extension)
        elsif a_file_extension =~ /\A\./
          # file_extension starts with '.', use as is
          a_file_extension
        elsif '' == a_file_extension
          # No extension given, use as is.
          a_file_extension
        else
          raise(ArgumentError.new("Invalid file_extension given: #{ a_file_extension.inspect }"))
        end
      end

      # Computes a glob file pattern from a_file_selector. Second segment of file_spec.
      # Guaranteed to have no leading or trailing slashes.
      # (see #compute_glob_pattern)
      def compute_file_selector(a_file_selector)
        a_file_selector = a_file_selector.to_s.strip
        if a_file_selector =~ FILE_SELECTOR_NAME_REGEX # e.g., 'all_files'
          # Use named file_selector from Rtfile
          file_selector(a_file_selector)
        elsif a_file_selector =~ /[\.\*\/]/
          # file_selector looks like path or file name (contains one of '.*/'),
          # use as is, remove leading and trailing slash
          a_file_selector.sub(/\A(\/*)/, '').sub(/(\/*)\z/, '')
        else
          raise(ArgumentError.new("Invalid file_selector given: #{ a_file_selector.inspect }"))
        end
      end

      # Computes a glob pattern from base_dir, file_selector and file_extension.
      # @param a_base_dir [String] either a named base_dir from Rtfile (e.g., 'content_dir'),
      #   or an absolute directory path (e.g., '/dir1/dir2')
      # @param a_file_selector [String] either a named file_selector from Rtfile (e.g., 'all_files')
      #   or a Dir.glob pattern (e.g., '**/*{65-0408}_*', 'validation_report')
      # @param a_file_extension [String] either a named file_extension from Rtfile,
      #   (e.g., 'at_file_extension'), or a Dir.glob pattern (e.g., '**/*.at')
      # @return [String] a file pattern that can be passed to Dir.glob, e.g., '/dir1/dir2/**/*.at'
      def compute_glob_pattern(a_base_dir, a_file_selector, a_file_extension)
        [
          compute_base_dir(a_base_dir),
          compute_file_selector(a_file_selector),
          compute_file_extension(a_file_extension)
        ].join
      end

      # Computes a hash with validation file specs from input_file_specs
      # @param input_file_specs [Hash] this hash will be transformed into a hash
      #     that can be passed to a validation as file_specs.
      #     keys: file spec names, e.g., :primary
      #     values: Array with three elements: base_dir, file_selector, file_extension
      # @return [Hash]
      def compute_validation_file_specs(input_file_specs)
        input_file_specs.inject({}) { |m,(fs_name, fs_attrs)|
          a_base_dir, a_file_selector, a_file_extension = fs_attrs
          m[fs_name] = [
            compute_base_dir(a_base_dir),
            compute_file_selector(a_file_selector),
            compute_file_extension(a_file_extension)
          ]
          m
        }
      end

      # Prints a pretty version of self
      def pretty_print
        puts
        puts "settings_hierarchy"
        puts @settings_hierarchy.ai(indent: -2)
        puts
        puts "execution context"
        puts @execution_context.ai(indent: -2)
        puts
        puts "effective_settings"
        puts @effective_settings.ai(indent: -2)
        puts
      end

      # Returns the absolute path of primary_content_type with a guaranteed
      # trailing slash at the end
      def primary_content_type_base_dir
        File.expand_path(
          setting(:relative_path_to_primary_content_type),
          base_dir(:content_type_dir)
        ).sub(/\/?\z/, '') + '/'
      end

    end
  end
end
