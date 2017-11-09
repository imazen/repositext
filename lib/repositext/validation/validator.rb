class Repositext
  class Validation
    # Abstract class for all validators. To comply with the Validator interface,
    # sub-classes have to implement the #run_list method.
    # @abstract
    class Validator

      extend Forwardable

      # Instantiates a new Validator.
      # @param file_to_validate [RFile, Array<RFile>]
      # @param logger [Logger]
      # @param reporter [Reporter]
      # @param options [Hash]
      def initialize(file_to_validate, logger, reporter, options)
        @file_to_validate = file_to_validate
        @logger = logger
        @reporter = reporter
        @options = options
      end

      # Call this method at the end of each run method in Validator subclasses
      # @param errors [Array] from the validation step
      # @param warnings [Array] from the validation step
      def log_and_report_validation_step(errors, warnings)
        @logger.log_validation_step(self, @file_to_validate, errors.none?)
        @reporter.add_errors(errors)
        @reporter.add_warnings(warnings)
      end

    end
  end
end
