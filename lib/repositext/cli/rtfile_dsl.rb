# Defines the DSL that can be used in Rtfiles
class Repositext
  class Cli
    module RtfileDsl

      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods

        # Tries to find Rtfile, starting in current working directory and
        # traversing up the directory hierarchy until it finds an Rtfile or
        # reaches the file system root.
        # NOTE: This code is inspired by Bundler's find_gemfile
        # @return[String, nil] path to closest Rtfile or nil if none found.
        def find_rtfile
          previous = nil
          current  = Dir.getwd

          until !File.directory?(current) || current == previous
            filename = File.join(current, 'Rtfile')
            return filename  if File.file?(filename)
            current, previous = File.expand_path("..", current), current
          end
          nil
        end

      end

      # Evaluates contents of Rtfile. Rtfile can call the DSL methods defined
      # below.
      # NOTE: This code is inspired by Bundler's eval_gemfile
      # @param[String] rtfile the path to the rtfile
      # @param[String, optional] contents allows passing of Rtfile contents as string, for testing.
      def eval_rtfile(rtfile, contents = nil)
        contents ||= File.open(rtfile, "rb") { |f| f.read }
        instance_eval(contents, rtfile.to_s, 1)
      rescue SyntaxError => e
        syntax_msg = e.message.gsub("#{ rtfile.to_s }:", 'on line ')
        raise RtfileError, "Rtfile syntax error #{ syntax_msg }"
      rescue ScriptError, RegexpError, NameError, ArgumentError => e
        e.backtrace[0] = "#{ e.backtrace[0] }: #{ e.message } (#{ e.class })"
        $stderr.puts e.backtrace.join("\n       ")
        raise RtfileError, "There was an error in your Rtfile."
      end

      # DSL methods

      # Used in Rtfile to define a base directory to be used by Dir.glob. Requires
      # either dir_string or dir_block
      # @param[String, Symbol] name the name of the dir by which it will be referenced
      # @param[String, optional] dir_string the base dir as string
      # @param[Proc] dir_block a block that returns the base dir as string
      def base_dir(name, dir_string = nil, &dir_block)
        if block_given?
          config.add_base_dir(name, dir_block.call)
        elsif dir_string
          config.add_base_dir(name, dir_string)
        else
          raise(RtfileError, "You must provide either dir_string or dir_block arguments to base_dir")
        end
        nil
      end

      # Used in Rtfile to define a file pattern to be used by Dir.glob. Requires
      # either pattern_string or pattern_block
      # @param[String, Symbol] name the name of the pattern by which it will be referenced
      # @param[String, optional] pattern_string the file pattern as string
      # @param[Proc] pattern_block a block that returns the file pattern as string
      def file_pattern(name, pattern_string = nil, &pattern_block)
        if block_given?
          config.add_file_pattern(name, pattern_block.call)
        elsif pattern_string
          config.add_file_pattern(name, pattern_string)
        else
          raise(RtfileError, "You must provide either pattern_string or pattern_block arguments to file_pattern")
        end
        nil
      end

      # Used in Rtfile to define a kramdown parser
      # @param[String, Symbol] name the name of the kramdown parser by which it will be referenced
      # @param[String] class_name the full class name of the parser to be used
      def kramdown_parser(name, class_name)
        config.add_kramdown_parser(name, class_name)
      end

      # Used in Rtfile to define a kramdown converter method
      # @param[String, Symbol] name the name of the kramdown converter method by which it will be referenced
      # @param[Symbol] method_name the name of the converter method, e.g., :to_kramdown
      def kramdown_converter_method(name, method_name)
        config.add_kramdown_converter_method(name, method_name)
      end

      # A method stub for testing this module
      def test
        # If 'test' is the last command in Rtfile, then eval_rtfile will return
        # the string below
        'test successful'
      end

      def method_missing(name, *args)
        location = caller[0].split(':')[0..1].join(':')
        raise RtfileError, "Undefined local variable or method `#{ name }' for Rtfile\n" \
          "        from #{ location }"
      end

    end
  end
end
