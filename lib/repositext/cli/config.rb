# Manages configuration of Cli instance (via Rtfile)
class Repositext
  class Cli
    class Config

      BASE_DIR_NAME_REGEX = /_dir\z/
      FILE_PATTERN_NAME_REGEX = /_files?\z/

      def initialize
        @base_dirs = {}
        @file_patterns = {}
        @kramdown_parsers = {}
        @kramdown_converter_methods = {}
      end

      # Use this method in DSL methods to add a base directory to config
      # @param[String, Symbol] name the name of the base dir under which it
      #     will be referenced.
      # @param[String] pattern_string A string with an absolute directory path
      def add_base_dir(name, base_dir_string)
        if name.to_s !~ BASE_DIR_NAME_REGEX
          raise ArgumentError.new("A base dir name must match this regex: #{ BASE_DIR_NAME_REGEX.inspect }")
        end
        # guarantee trailing slash
        bd = base_dir_string.to_s.gsub(/\/\z/, '') + '/'
        @base_dirs[name.to_sym] = bd
      end

      # Use this method in DSL methods to add a file pattern to config
      # @param[String, Symbol] name the name of the file pattern under which it
      #     will be referenced
      # @param[String] pattern_string A string with an absolute file path that can be
      #     passed to Dir.glob
      def add_file_pattern(name, pattern_string)
        if name.to_s !~ FILE_PATTERN_NAME_REGEX
          raise ArgumentError.new("A file pattern name must match this regex: #{ FILE_PATTERN_NAME_REGEX.inspect }")
        end
        @file_patterns[name.to_sym] = pattern_string.to_s
      end

      # Use this method in DSL methods to add a kramdown converter method to config
      # @param[String, Symbol] name the name of the kramdown converter method under which it
      #     will be referenced
      # @param[Symbol] method_name the name of the method
      def add_kramdown_converter_method(name, method_name)
        @kramdown_converter_methods[name.to_sym] = method_name.to_sym
      end

      # Use this method in DSL methods to add a parser to config
      # @param[String, Symbol] name the name of the parser under which it
      #     will be referenced
      # @param[String] class_name the complete name of the parser class. Will be constantized.
      def add_kramdown_parser(name, class_name)
        @kramdown_parsers[name.to_sym] = Object.const_get(class_name)
      end

      # Retrieve a base dir
      # @param[String, Symbol] name
      def base_dir(name)
        if name.to_s !~ BASE_DIR_NAME_REGEX
          raise ArgumentError.new("A base dir name must match this regex: #{ BASE_DIR_NAME_REGEX.inspect }")
        end
        get_config_val(@base_dirs, name)
      end

      # Retrieve a file pattern
      # @param[String, Symbol] name
      def file_pattern(name)
        if name.to_s !~ FILE_PATTERN_NAME_REGEX
          raise ArgumentError.new("A file pattern name must match this regex: #{ FILE_PATTERN_NAME_REGEX.inspect }")
        end
        get_config_val(@file_patterns, name)
      end

      # Retrieve a kramdown converter method
      # @param[String, Symbol] name
      def kramdown_converter_method(name)
        get_config_val(@kramdown_converter_methods, name)
      end

      # Retrieve a kramdown parser
      # @param[String, Symbol] name
      def kramdown_parser(name)
        get_config_val(@kramdown_parsers, name)
      end

      # Computes a glob pattern from file spec
      # @param[String] file_spec a file specification in one of two formats:
      #     1) Named base_dir and file_pattern from Rtfile, e.g., 'content_dir/at_files'
      #     2) Dir.glob pattern, e.g., '/dir1/dir2/**/*.at'
      # @return[String] a file pattern that can be passed to Dir.glob
      def compute_glob_pattern(file_spec)
        segments = file_spec.split(Repositext::Cli::FILE_SPEC_DELIMITER)
        r = ''
        if segments.all? { |e| e =~ BASE_DIR_NAME_REGEX || e =~ FILE_PATTERN_NAME_REGEX }
          # file_spec consists of named base_dir and/or file_pattern
          bd = segments.detect { |e| e =~ BASE_DIR_NAME_REGEX } # e.g., 'content_dir'
          fp = segments.detect { |e| e =~ FILE_PATTERN_NAME_REGEX } # e.g., 'at_files'
          r << base_dir(bd)  if bd
          r << file_pattern(fp)  if fp
        else
          # interpret file_spec as glob pattern.
          # NOTE: this doesn't necessarily have to contain '*'. It could be the
          # path to a single file.
          r = file_spec
        end
        r
      end

      # Computes a hash with validation file specs from input_file_specs
      # @param[Hash] input_file_specs this hash will be transformed into a hash
      #     that can be passed to a validation as file_specs.
      # @return[Hash]
      def compute_validation_file_specs(input_file_specs)
        input_file_specs.inject({}) { |m,(fs_name, fs_string)|
          base_dir, file_pattern = fs_string.split(Repositext::Cli::FILE_SPEC_DELIMITER).compact
          if base_dir.nil? || file_pattern.nil?
            raise ArgumentError.new("file_spec requires both base_dir and file_pattern: #{ fs_string.inspect } in #{ input_file_specs.inspect }")
          end
          if base_dir !~ BASE_DIR_NAME_REGEX
            raise ArgumentError.new("base_dir is not valid: #{ base_dir.inspect }")
          end
          if file_pattern !~ FILE_PATTERN_NAME_REGEX
            raise ArgumentError.new("file_pattern is not valid: #{ file_pattern.inspect }")
          end
          m[fs_name] = [base_dir(base_dir), file_pattern(file_pattern)]
          m
        }
      end

    private

      # Returns a key's value from container. Raises if an unknown key is requested.
      # @param[Hash] container the Hash that contains the key
      # @param[Symbol] key
      # @param[Boolean, optional] raise_on_unknown_key
      def get_config_val(container, key, raise_on_unknown_key = true)
        key = key.to_sym
        if raise_on_unknown_key && !container.keys.include?(key)
          raise ArgumentError.new("You requested an unknown key: #{ key.inspect }")
        end
        container[key]
      end

    end
  end
end
