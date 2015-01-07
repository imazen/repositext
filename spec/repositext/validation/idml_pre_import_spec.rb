require_relative '../../helper'
require_relative 'shared_spec_behaviors'

class Repositext
  class Validation
    describe IdmlPreImport do

      include SharedSpecBehaviors

      before {
        @common_validation = IdmlPreImport.new(
          {:primary => ['_', '_', '_']}, {}
        )
      }

    end
  end
end
