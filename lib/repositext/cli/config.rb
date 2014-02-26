# Manages configuration of Cli instance (via Rtfile)
class Repositext
  class Cli
    class Config

      # @param[Repositext::Cli] cli_instance
      def initialize(cli_instance)
        @cli_instance = cli_instance
        @file_patterns = {}
        @kramdown_parsers = {}
        @kramdown_converter_methods = {}
      end

      # Use this method in DSL methods to add a file pattern to config
      # @param[String, Symbol] name the name of the file pattern under which it
      #     will be referenced
      # @param[Proc] block the block that is called to compute the file pattern.
      #     Block has to return a string that can be passed to Dir.glob
      def add_file_pattern(name, block)
        # TODO: currently we evaluate blocks at DSL load time. We could further
        # delay evaluation to when a file_pattern is read (via #file_pattern reader)
        @file_patterns[name.to_sym] = block.call
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

      # Retrieve a file pattern
      # @param[String, Symbol] name
      def file_pattern(name)
        @file_patterns[name.to_sym]
      end

      # Retrieve a kramdown converter method
      # @param[String, Symbol] name
      def kramdown_converter_method(name)
        @kramdown_converter_methods[name.to_sym]
      end

      # Retrieve a kramdown parser
      # @param[String, Symbol] name
      def kramdown_parser(name)
        @kramdown_parsers[name.to_sym]
      end

    end
  end
end
