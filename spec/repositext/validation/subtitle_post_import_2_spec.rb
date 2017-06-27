require_relative '../../helper'
require_relative 'shared_spec_behaviors'

class Repositext
  class Validation
    describe SubtitlePostImport2 do

      include SharedSpecBehaviors

      before {
        @common_validation = SubtitlePostImport2.new(
          {:primary => ['_', '_', '_']}, {}
        )
      }

    end
  end
end
