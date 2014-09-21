require_relative '../../helper'

describe Repositext::Validation::FolioXmlPostImport do

  include Repositext::SharedSpecBehaviors::Validations

  before {
    @common_validation = Repositext::Validation::FolioXmlPostImport.new(
      {:primary => ['_', '_']}, {}
    )
  }

end
