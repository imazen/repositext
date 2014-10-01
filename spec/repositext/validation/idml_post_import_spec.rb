require_relative '../../helper'
require_relative 'shared_spec_behaviors'

class Repositext
  class Validation
    describe IdmlPostImport do

      include SharedSpecBehaviors

      before {
        @common_validation = IdmlPostImport.new(
          {:primary => ['_', '_']}, {}
        )
      }

    end
  end
end
