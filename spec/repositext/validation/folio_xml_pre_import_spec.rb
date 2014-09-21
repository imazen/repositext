require_relative '../../helper'

describe Repositext::Validation::FolioXmlPreImport do

  include Repositext::SharedSpecBehaviors::Validations

  before {
    @common_validation = Repositext::Validation::FolioXmlPreImport.new(
      {:primary => ['_', '_']}, {}
    )
  }

end
