require_relative '../../helper'

describe Repositext::Validation::IdmlPreImport do

  include Repositext::SharedSpecBehaviors::Validations

  before {
    @common_validation = Repositext::Validation::IdmlPreImport.new(
      {:primary => ['_', '_']}, {}
    )
  }

end
