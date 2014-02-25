# Defines the DSL that can be used in Rtfiles
class Repositext
  class Rt
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
        end

      end

      # Evaluates contents of Rtfile. Rtfile can call the DSL methods defined
      # below.
      # NOTE: This code is inspired by Bundler's eval_gemfile
      # @param[String] rtfile_path
      # @param[String, optional] contents allows passing of Rtfile contents as string, for testing.
      def eval_rtfile(rtfile, contents = nil)
        contents ||= File.open(rtfile, "rb") { |f| f.read }
        instance_eval(contents, rtfile.to_s, 1)
      rescue SyntaxError => e
        syntax_msg = e.message.gsub("#{ rtfile.to_s }:", 'on line ')
        raise RtfileError, "Rtfile syntax error #{ syntax_msg }"
      rescue ScriptError, RegexpError, NameError, ArgumentError => e
        e.backtrace[0] = "#{ e.backtrace[0] }: #{ e.message } (#{ e.class })"
        STDERR.puts e.backtrace.join("\n       ")
        raise RtfileError, "There was an error in your Rtfile."
      end

      # DSL methods

      # Example for simple dsl method
      def dsl_method(name, *args)
        STDERR.puts " from dsl_method:"
        STDERR.puts "  - name = #{ name.inspect }"
        STDERR.puts "  - args = #{ args.inspect }"
      end

      # Example for a dsl method with a block
      def dsl_method_with_block(*args, &block)
        STDERR.puts " from dsl_method_with_block:"
        STDERR.puts "  - args = #{ args.inspect }"
        yield # anything we need to yield to the block?
      ensure
        # any cleanup that needs to be done
      end

      def method_missing(name, *args)
        location = caller[0].split(':')[0..1].join(':')
        raise RtfileError, "Undefined local variable or method `#{ name }' for Rtfile\n" \
          "        from #{ location }"
      end

    end
  end
end
