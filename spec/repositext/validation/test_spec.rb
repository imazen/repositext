require_relative '../../helper'
require_relative 'shared_spec_behaviors'

class Repositext
  class Validation
    describe Test do

      include SharedSpecBehaviors

      before {
        @common_validation = Test.new(
          {:primary => ['_', '_', '_']}, {}
        )
      }

    end
  end
end
