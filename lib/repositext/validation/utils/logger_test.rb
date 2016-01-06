class Repositext
  class Validation

    # This logger is for testing. It doesn't log anything to keep the spec
    # output clean.
    class LoggerTest

      attr_accessor :level

      # @param _input_base_dir [String] part of file_spec
      # @param _file_selector [String] part of file_spec
      # @param _file_extension [String] part of file_spec
      # @param _log_level [String] one of 'debug', 'info', 'warning', 'error'
      # @param _validation [Repositext::Validation]
      def initialize(_input_base_dir, _file_selector, _file_extension, _log_level, _validation)
      end

      # @param[Object] loggable
      def debug(loggable)
      end

      # @param[Object] loggable
      def info(loggable)
      end

      # @param[Object] loggable
      def warning(loggable)
      end

      # @param[Object] loggable
      def error(loggable)
      end

      # Logs a header for validation
      # @param _file_spec [String] the complete glob pattern
      # @param _validation_class [Class]
      def validation_header(_file_spec, _validation_class)
      end

      # @param[Reporter] _reporter
      # @param[Float] _run_time in seconds
      def validation_footer(_reporter, _run_time)
      end

      # @param[Validator] _validator
      # @param[String, Array<String>] _file_descriptor
      # @param[Boolean] _success
      def log_validation_step(_validator, _file_descriptor, _success)
      end

    end
  end
end
