require_relative '../../helper'
require_relative 'shared_spec_behaviors'

class Repositext
  class Validation
    describe Content do

      include SharedSpecBehaviors

      before {
        @common_validation = Content.new(
          {:primary => ['_', '_']}, {}
        )
      }

    end
  end
end
