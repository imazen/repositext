require_relative '../../helper'
require_relative 'shared_spec_behaviors'

class Repositext
  class Validation
    describe FolioXmlPreImport do

      include SharedSpecBehaviors

      before {
        @common_validation = FolioXmlPreImport.new(
          {:primary => ['_', '_', '_']}, {}
        )
      }

    end
  end
end
