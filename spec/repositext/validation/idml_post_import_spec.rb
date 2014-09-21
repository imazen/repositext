require_relative '../../helper'

describe Repositext::Validation::IdmlPostImport do

  include Repositext::SharedSpecBehaviors::Validations

  before {
    @common_validation = Repositext::Validation::IdmlPostImport.new(
      {:primary => ['_', '_']}, {}
    )
  }

end
