require_relative '../../helper'

describe Repositext::Validation::GapMarkTaggingPostImport do

  include Repositext::SharedSpecBehaviors::Validations

  before {
    @common_validation = Repositext::Validation::GapMarkTaggingPostImport.new(
      {:primary => ['_', '_']}, {}
    )
  }

end
