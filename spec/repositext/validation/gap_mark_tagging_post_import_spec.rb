require_relative '../../helper'
require_relative 'shared_spec_behaviors'

class Repositext
  class Validation
    describe GapMarkTaggingPostImport do

      include SharedSpecBehaviors

      before {
        @common_validation = GapMarkTaggingPostImport.new(
          {:primary => ['_', '_']}, {}
        )
      }

    end
  end
end
