# Manages configuration of Rt instance (via Rtfile)
class Repositext
  class Rt
    class Config

      # @param[Repositext::Rt] rt_instance
      def initialize(rt_instance)
        @rt_instance = rt_instance
        @file_patterns = {}
        @parsers = {}
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

      # Use this method in DSL methods to add a parser to config
      # @param[String, Symbol] name the name of the parser under which it
      #     will be referenced
      # @param[String] class_name the complete name of the parser class. Will be constantized.
      def add_parser(name, class_name)
        @parsers[name.to_sym] = Object.const_get(class_name)
      end

      # Retrieve a file pattern
      # @param[String, Symbol] name
      def file_pattern(name)
        @file_patterns[name.to_sym]
      end

      # Retrieve a parser
      # @param[String, Symbol] name
      def parser(name)
        @parsers[name.to_sym]
      end

    end
  end
end
