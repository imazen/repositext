# Defines the DSL that can be used in Rtfiles
class Repositext
  class Cli
    class RtfileParser

      attr_reader :config

      # @param config_object [Repositext::Cli::Config]
      def initialize(config)
        @config = config
      end

      # Evaluates contents of Rtfile. Rtfile can call the DSL methods defined
      # below.
      # NOTE: This code is inspired by Bundler's eval_gemfile
      # @param rtfile [String] the path to the rtfile
      # @param contents [String, optional] allows passing of Rtfile contents as string, for testing.
      def eval_rtfile(rtfile, contents = nil)
        contents ||= File.open(rtfile, 'r', &:read)
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
      # @param name [String, Symbol] the name of the dir by which it will be referenced
      # @param dir_string [String, optional] the base dir as string
      # @param dir_block [Proc] a block that returns the base dir as string
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

      # Used in Rtfile to define a file extension to be used by Dir.glob. Requires
      # either extension_string or extension_block
      # @param name [String, Symbol] the name of the extension by which it will be referenced
      # @param extension_string [String, optional] the file extension as string
      # @param extension_block [Proc] a block that returns the file extension as string
      def file_extension(name, extension_string = nil, &extension_block)
        if block_given?
          config.add_file_extension(name, extension_block.call)
        elsif extension_string
          config.add_file_extension(name, extension_string)
        else
          raise(RtfileError, "You must provide either extension_string or extension_block arguments to file_extension")
        end
        nil
      end

      # Used in Rtfile to define a file selector to be used by Dir.glob. Requires
      # either selector_string or selector_block
      # @param name [String, Symbol] the name of the selector by which it will be referenced
      # @param selector_string [String, optional] the file selector as string
      # @param selector_block [Proc] a block that returns the file selector as string
      def file_selector(name, selector_string = nil, &selector_block)
        if block_given?
          config.add_file_selector(name, selector_block.call)
        elsif selector_string
          config.add_file_selector(name, selector_string)
        else
          raise(RtfileError, "You must provide either selector_string or selector_block arguments to file_selector")
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

      # Used in Rtfile to define a repository wide setting.
      # @param[String, Symbol] setting_key
      # @apram[Object] setting_val
      def setting(setting_key, setting_val)
        config.add_setting(setting_key, setting_val)
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
