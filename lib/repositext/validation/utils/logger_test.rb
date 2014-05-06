class Repositext
  class Validation

    # This logger is for testing. It doesn't log anything to keep the spec
    # output clean.
    class LoggerTest

      attr_accessor :level

      # @param[String] _file_pattern_base_path
      # @param[String] _file_pattern
      # @param[String] _log_level
      # @param[Repositext::Validation] validation
      def initialize(_file_pattern_base_path, _file_pattern, _log_level, _validation)
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
      # @param[String] _file_pattern
      # @param[Class] _validation_class
      def validation_header(_file_pattern, _validation_class)
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
