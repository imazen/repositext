# Manages configuration of Cli instance (via Rtfile)
class Repositext
  class Cli
    class Config

      attr_accessor :rtfile_dir

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
        if name.to_s !~ /_dir\z/
          raise ArgumentError.new("A base dir name must end with '_dir'")
        end
        @base_dirs[name.to_sym] = base_dir_string.to_s
      end

      # Use this method in DSL methods to add a file pattern to config
      # @param[String, Symbol] name the name of the file pattern under which it
      #     will be referenced
      # @param[String] pattern_string A string with an absolute file path that can be
      #     passed to Dir.glob
      def add_file_pattern(name, pattern_string)
        if name.to_s !~ /_files\z/
          raise ArgumentError.new("A file pattern name must end with '_files'")
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
        if name.to_s !~ /_dir\z/
          raise ArgumentError.new("A base dir name must end with '_dir'")
        end
        get_config_val(@base_dirs, name)
      end

      # Retrieve a file pattern
      # @param[String, Symbol] name
      def file_pattern(name)
        if name.to_s !~ /_files\z/
          raise ArgumentError.new("A file pattern name must end with '_files'")
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
      # @param[String] file_spec a file specification in the form of e.g., 'master_dir.at_files'
      # @return[String] a file pattern that can be passed to Dir.glob
      def compute_glob_pattern(file_spec)
        segments = file_spec.split('.')
        bd = segments.detect { |e| e =~ /_dir\z/ } # e.g., 'master_dir'
        fp = segments.detect { |e| e =~ /_files\z/ } # e.g., 'at_files'
        r = ''
        r << base_dir(bd)  if bd
        r << file_pattern(fp)  if fp
        r
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
