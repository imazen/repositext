class Repositext
  class Validation

    # The Logger class provides a base for all repositext-validation loggers.
    # It uses the `Logging` gem for added functionality.
    # A logger's job is to log the progress of a validation. Typically it would
    # print log messages to $stdout, and possibly to a log file.
    class Logger

      attr_accessor :level

      # @param _input_base_dir [String] part of file_spec
      # @param _file_selector [String] part of file_spec
      # @param _file_extension [String] part of file_spec
      # @param _log_level [String] one of 'debug', 'info', 'warning', 'error'
      # @param _validation [Repositext::Validation]
      def initialize(_input_base_dir, _file_selector, _file_extension, _log_level, _validation)
        @file_extension = _file_extension
        @file_selector = _file_selector
        @input_base_dir = _input_base_dir
        @validation = _validation
        @level = _log_level

        # Delegate to Logging framework
        @logging = Logging.logger[' ']
        # `Logging.logger` returns any existing instances when called with the
        # same device (' ' in this case). So we need to clear any existing
        # appenders first. Otherwise we'd add another appender and each log
        # line would appear twice in the console.
        @logging.clear_appenders
        @logging.add_appenders(
          #Logging.appenders.stdout(:layout => Logging.layouts.repositext_basic)
          Logging.appenders.stdout(:layout => Logging.layouts.pattern(:pattern => '%-5l %m\n'))
        )
        @logging.level = @level
      end

      # @param [Object] loggable
      def debug(loggable)
        @logging.debug(loggable)
      end

      # @param [Object] loggable
      def info(loggable)
        @logging.info(loggable)
      end

      # @param [Object] loggable
      def warning(loggable)
        @logging.warn(loggable)
      end

      # @param [Object] loggable
      def error(loggable)
        @logging.error(loggable.color(:red))
      end

      # Logs a header for validation
      # @param _file_spec [String] the complete glob pattern
      # @param _validation_class [Class]
      def validation_header(_file_spec, _validation_class)
        info '=' * 80
        info 'Repositext Validation'
        info '=' * 80
        info "  - validation: #{ _validation_class.to_s.split('::').last(2).join('::') }"
        info "  - file spec:  #{ _file_spec }"
        info "  - log level:  #{ @level }"
        info '=' * 80
      end

      # Logs a footer for validation
      # @param [Reporter] _reporter
      # @param [Float] _run_time in seconds
      def validation_footer(_reporter, _run_time)
        case (c = _reporter.errors.count)
        when 0
          info '=' * 80
          info sprintf("Validation took %.2f seconds.", _run_time)
          info 'There were no validation errors.'
        when 1
          error '=' * 80
          info sprintf("Validation took %.2f seconds.", _run_time)
          error "There was 1 validation error."
        else
          error '=' * 80
          info sprintf("Validation took %.2f seconds.", _run_time)
          error "There were #{ c } validation errors."
        end
      end

      # @param _validator [Validator]
      # @param _io_or_string_or_array [IO, String, RFile, Array<IO, String, RFile>] the source
      #   file (or path as String) in which the validation step was defined.
      # @param _success [Boolean]
      def log_validation_step(_validator, _io_or_string_or_array, _success)
        # We want to keep the full path names so that we can open the files
        # easily in sublime text by command clicking them in the terminal.
        # Cast _io_or_string_or_array to array
        io_or_string_array = if _io_or_string_or_array.is_a?(Array)
          _io_or_string_or_array
        else
          [_io_or_string_or_array]
        end
        string_array = io_or_string_array.map { |e|
          case e
          when IO
            e.path
          when Repositext::RFile
            e.filename
          when String
            e
          else
            raise "Handle this: #{ e.inspect }"
          end
        }
        parts = [
          '  ',
          string_array.join(', '),
          ' ',
          _validator.class.name.split(/::/).last.ljust(30)
        ]
        _success ? info(parts.join) : error(parts.join)
      end

      # @param [IO, String, Array<IO, String>] _io
      # @param [Array<String>] _info
      def log_debug_info(_io, _info)
        io_or_string_array = _io.is_a?(Array) ? _io : [_io] # cast _io to array
        string_array = io_or_string_array.map { |e|
          case e
          when IO
            e.path
          when String
            e
          else
            raise "Handle this: #{ e.inspect }"
          end
        }
        parts = [
          '  ',
          string_array.join(', ').gsub(@input_base_dir, '').ljust(32),
          ' ',
          _info.join(', ').ljust(30)
        ]
        debug(parts.join)
      end

    end
  end
end
