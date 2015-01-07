require_relative '../../helper'
require_relative 'shared_spec_behaviors'

class Repositext
  class Validation
    describe Rtfile do

      include SharedSpecBehaviors

      before {
        @common_validation = Rtfile.new(
          {:primary => ['_', '_', '_']}, {}
        )
      }

    end
  end
end
