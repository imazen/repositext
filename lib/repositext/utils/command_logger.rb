class Repositext
  class Utils
    # Logs a command's output to console or file.
    # Usage:
    #     @logger = Repositext::Utils::CommandLogger.new(opts)
    # Then in the command to log:
    #     @logger.info("Hello world!")
    class CommandLogger

      # @param attrs [Hash{Symbol => Object}]
      # @option attrs [Boolean] active, defaults to true. If false, output will be suppressed.
      # @option attrs [Symbol, Nil] color_override will use this color (independent of colorize)
      # @option attrs [Boolean] colorize, defaults to true.
      # @option attrs [Symbol] min_level, one of :debug, :info, :warning, :error (in that order).
      # @option attrs [IO] output_destination, defaults to $stdout. Alternatively
      #   you could use `StringIO.new`.
      # @option attrs [String] prefix, will be prepended to every line.
      def initialize(attrs={})
        @attrs = {
          active: true,
          color_override: nil,
          colorize: true,
          min_level: :info,
          output_destination: $stdout,
          prefix: '',
        }.merge(attrs)
      end

      # @param msg [String]
      # @param attrs [Hash{Symbol => Object}]
      def debug(msg, attrs={})
        log_message(msg, :debug, @attrs.merge(attrs))
      end

      # @param msg [String]
      # @param attrs [Hash{Symbol => Object}]
      def info(msg, attrs={})
        log_message(msg, :info, @attrs.merge(attrs))
      end

      # @param msg [String]
      # @param attrs [Hash{Symbol => Object}]
      def warning(msg, attrs={})
        log_message(msg, :warning, @attrs.merge(attrs))
      end

      # @param msg [String]
      # @param attrs [Hash{Symbol => Object}]
      def error(msg, attrs={})
        log_message(msg, :error, @attrs.merge(attrs))
      end

    protected

      def color_for_level(level)
        case level
        when :debug
          nil
        when :info
          nil
        when :warning
          :orange
        when :error
          :red
        end
      end

      def compute_color(level, attrs)
        if attrs[:color_override]
          attrs[:color_override]
        elsif attrs[:colorize]
          color_for_level(level)
        else
          nil
        end
      end

      def log_message(msg, level, attrs)
        return false  unless attrs[:active] # logging is turned off
        return false  unless print_level?(attrs[:min_level], level) # level is ignored

        # NOTE: This block is not very elegant, however I had trouble between
        # the Rainbow color gem and concatenating prefix and msg. The below works.
        str = [attrs[:prefix].to_s, msg].join
        if(clr = compute_color(level, attrs))
          attrs[:output_destination].puts(str.color(clr))
        else
          attrs[:output_destination].puts(str)
        end
      end

      # Returns true if level is at or above min_level.
      # @param min_level [Symbol]
      # @param level [Symbol]
      def print_level?(min_level, level)
        printed_levels(min_level).include?(level)
      end

      # Returns an array of levels to be printed given min_level
      # @param min_level [Symbol]
      def printed_levels(min_level)
        case min_level
        when :debug
          [:error, :warning, :info, :debug]
        when :info
          [:error, :warning, :info]
        when :warning
          [:error, :warning]
        when :error
          [:error]
        else
          raise "Handle this: #{ min_level.inspect }"
        end
      end

    end
  end
end
