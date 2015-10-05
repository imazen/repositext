# Manages configuration of Cli instance (via Rtfile)
class Repositext
  class Cli
    class Config

      BASE_DIR_NAME_REGEX = /\A\w+_dir\z/
      FILE_EXTENSION_NAME_REGEX = /\A\w+_extensions?\z/
      FILE_SELECTOR_NAME_REGEX = /\A\w+_files?\z/

      def initialize(rtfile_path)
        @rtfile_path = rtfile_path
        @base_dirs = {}
        @file_selectors = {}
        @file_extensions = {}
        @kramdown_converter_methods = {}
        @kramdown_parsers = {}
        @settings = {}
      end

      def eval
        RtfileParser.new(self).eval_rtfile(@rtfile_path)
      end

      # Use this method in DSL methods to add a base directory to config
      # @param name [String, Symbol] the name of the base dir under which it
      #     will be referenced.
      # @param pattern_string [String] A string with an absolute directory path
      def add_base_dir(name, base_dir_string)
        if name.to_s !~ BASE_DIR_NAME_REGEX
          raise ArgumentError.new("A base dir name must match this regex: #{ BASE_DIR_NAME_REGEX.inspect }")
        end
        # guarantee trailing slash
        bd = base_dir_string.to_s.gsub(/\/\z/, '') + '/'
        @base_dirs[name.to_sym] = bd
      end

      # Use this method in DSL methods to add a file extension to config
      # @param name [String, Symbol] the name of the file extension under which it
      #     will be referenced
      # @param extension_string [String] A string with an absolute file path that can be
      #     passed to Dir.glob
      def add_file_extension(name, extension_string)
        if name.to_s !~ FILE_EXTENSION_NAME_REGEX
          raise ArgumentError.new("A file extension name must match this regex: #{ FILE_EXTENSION_NAME_REGEX.inspect }")
        end
        @file_extensions[name.to_sym] = extension_string.to_s
      end

      # Use this method in DSL methods to add a file selector to config
      # @param name [String, Symbol] the name of the file selector under which it
      #     will be referenced
      # @param selector_string [String] A string with an absolute file path that can be
      #     passed to Dir.glob
      def add_file_selector(name, selector_string)
        if name.to_s !~ FILE_SELECTOR_NAME_REGEX
          raise ArgumentError.new("A file selector name must match this regex: #{ FILE_SELECTOR_NAME_REGEX.inspect }")
        end
        @file_selectors[name.to_sym] = selector_string.to_s
      end

      # Use this method in DSL methods to add a kramdown converter method to config
      # @param name [String, Symbol] the name of the kramdown converter method under which it
      #     will be referenced
      # @param method_name [Symbol] the name of the method
      def add_kramdown_converter_method(name, method_name)
        @kramdown_converter_methods[name.to_sym] = method_name.to_sym
      end

      # Use this method in DSL methods to add a parser to config
      # @param name [String, Symbol] the name of the parser under which it
      #     will be referenced
      # @param class_name [String] the complete name of the parser class. Will be constantized.
      def add_kramdown_parser(name, class_name)
        @kramdown_parsers[name.to_sym] = Object.const_get(class_name)
      end

      # Use this method in DSL methods to add a setting.
      # @param setting_key [String, Symbol]
      # @param setting_val [Object]
      def add_setting(setting_key, setting_val)
        @settings[setting_key.to_sym] = setting_val
      end

      # Retrieve a base dir
      # @param name [String, Symbol]
      def base_dir(name)
        if name.to_s !~ BASE_DIR_NAME_REGEX
          raise ArgumentError.new("A base dir name must match this regex: #{ BASE_DIR_NAME_REGEX.inspect }")
        end
        get_config_val(@base_dirs, name)
      end

      # Retrieve a file extension
      # @param name [String, Symbol]
      def file_extension(name)
        if name.to_s !~ FILE_EXTENSION_NAME_REGEX
          raise ArgumentError.new("A file pattern name must match this regex: #{ FILE_EXTENSION_NAME_REGEX.inspect }")
        end
        get_config_val(@file_extensions, name)
      end

      # Retrieve a file selector
      # @param name [String, Symbol]
      def file_selector(name)
        if name.to_s !~ FILE_SELECTOR_NAME_REGEX
          raise ArgumentError.new("A file pattern name must match this regex: #{ FILE_SELECTOR_NAME_REGEX.inspect }")
        end
        get_config_val(@file_selectors, name)
      end

      # Retrieve a kramdown converter method
      # @param name [String, Symbol]
      def kramdown_converter_method(name)
        get_config_val(@kramdown_converter_methods, name)
      end

      # Retrieve a kramdown parser
      # @param name [String, Symbol]
      def kramdown_parser(name)
        get_config_val(@kramdown_parsers, name)
      end

      # @param key [Symbol]
      # @param raise_on_unknown_key [Boolean, optional] defaults to true. Set to false for optional settings
      def setting(key, raise_on_unknown_key = true)
        get_config_val(@settings, key, raise_on_unknown_key)
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

      # Returns the absolute path of primary_repo with a guaranteed trailing
      # slash at the end
      def primary_repo_base_dir
        File.expand_path(
          setting(:relative_path_to_primary_repo),
          base_dir(:rtfile_dir)
        ).sub(/\/?\z/, '') + '/'
      end

    private

      # Returns a key's value from container. Raises if an unknown key is requested.
      # @param container [Hash] the Hash that contains the key
      # @param key [Symbol]
      # @param raise_on_unknown_key [Boolean, optional]
      def get_config_val(container, key, raise_on_unknown_key = true)
        key = key.to_sym
        if raise_on_unknown_key && !container.keys.include?(key)
          raise RtfileError.new("You requested an unknown key: #{ key.inspect }")
        end
        # NOTE: Avoid accidental changes to config values via destructive methods or '<<'!!
        container[key].freeze
      end

    end
  end
end
