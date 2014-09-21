class Repositext
  module SharedSpecBehaviors
    module Validators

      # Returns an array with validator, logger, and reporter instances
      # @param[Class] klass a validator class
      # @param[IO, optional] file_to_validate
      # @param[Logger, optional] logger
      # @param[Reporter, optional] reporter
      # @param[Hash, optional] options
      def build_validator_logger_and_reporter(klass, file_to_validate=nil, logger=nil, reporter=nil, options={})
        file_to_validate ||= StringIO.new('a simple string')
        logger ||= Validation::LoggerTest.new(nil, nil, nil, nil)
        reporter ||= Validation::ReporterTest.new(nil, nil, nil)
        options = {
          'kramdown_validation_parser_class' => Kramdown::Parser::KramdownValidation,
          'run_options' => [],
        }.merge(options)
        validator = klass.new(
          file_to_validate,
          logger,
          reporter,
          options
        )
        [validator, logger, reporter]
      end

    end
  end
end
