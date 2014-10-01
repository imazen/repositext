require_relative '../../helper'
require_relative 'shared_spec_behaviors'

class Repositext
  class Validation
    describe GapMarkTaggingPreImport do

      include SharedSpecBehaviors

      before {
        @common_validation = GapMarkTaggingPreImport.new(
          {:primary => ['_', '_']}, {}
        )
      }

    end
  end
end
