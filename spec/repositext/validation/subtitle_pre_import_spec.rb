require_relative '../../helper'
require_relative 'shared_spec_behaviors'

class Repositext
  class Validation
    describe SubtitlePreImport do

      include SharedSpecBehaviors

      before {
        @common_validation = SubtitlePreImport.new(
          {:primary => ['_', '_', '_']}, {}
        )
      }

    end
  end
end
