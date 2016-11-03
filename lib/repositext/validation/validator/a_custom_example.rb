class Repositext
  class Validation
    class Validator
      # Use this class as a template for creating custom Validators
      class ACustomExample < Validator

        # Every validator needs a `run` method. This gets called from the validation.
        # A Validator has access to the following instance variables:
        #   @file_to_validate - the name of the file to validate, [String]
        #
        # For reporting, pass any errors and warnings to the log_and_report_validation_step
        # method. Each error or warning must be of class Repositext::Validation::Reportable.
        #
        # Outcome is a good vehicle to return validation outcomes to the run method.
        def run
          document_to_validate = @file_to_validate.read
          outcome = is_this_valid?(document_to_validate)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

        # This is where you check the validatable for any issues
        # @param [Object] validatable whichever you validate: a file, a string, ...
        # @return [Repositext::Validation::Outcome]
        # TODO: give this method a more meaningful name, e.g., "utf8_encoded?"
        # and change it accordingly in the `run` method.
        def is_this_valid?(validatable)
          errors = []
          warnings = []

          # Run some validation checks here ...
          # add errors:
          if 'error_condition'
            errors << Reportable.error(
              [@file_to_validate.path, 'describe location of error'],
              ["Error class", "Error description"]
            )
          end
          if 'warning_condition'
            warnings << Reportable.warning(
              [@file_to_validate.path, 'describe location of error'],
              ["Warning class", "Warning description"]
            )
          end

          Outcome.new(errors.empty?, nil, [], errors, warnings)
        end

      end
    end
  end
end
