require_relative '../../helper'

describe Repositext::Validation::GapMarkTaggingPreImport do

  include Repositext::SharedSpecBehaviors::Validations

  before {
    @common_validation = Repositext::Validation::GapMarkTaggingPreImport.new(
      {:primary => ['_', '_']}, {}
    )
  }

end
