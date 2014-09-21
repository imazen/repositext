require_relative '../../helper'

describe Repositext::Validation::Test do

  include Repositext::SharedSpecBehaviors::Validations

  before {
    @common_validation = Repositext::Validation::Test.new(
      {:primary => ['_', '_']}, {}
    )
  }

end
