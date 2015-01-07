require_relative '../../helper'
require 'repositext/validation/a_custom_example' # have to manually require this validation
require_relative 'shared_spec_behaviors'

class Repositext
  class Validation

    describe ACustomExample do

      include SharedSpecBehaviors

      before {
        @common_validation = ACustomExample.new(
          {:primary => ['_', '_', '_']}, {}
        )
      }

    end
  end
end
