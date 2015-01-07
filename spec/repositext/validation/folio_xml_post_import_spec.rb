require_relative '../../helper'
require_relative 'shared_spec_behaviors'

class Repositext
  class Validation
    describe FolioXmlPostImport do

      include SharedSpecBehaviors

      before {
        @common_validation = FolioXmlPostImport.new(
          {:primary => ['_', '_', '_']}, {}
        )
      }

    end
  end
end
