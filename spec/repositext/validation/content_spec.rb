require_relative '../../helper'

describe Repositext::Validation::Content do

  include Repositext::SharedSpecBehaviors::Validations

  before {
    @common_validation = Repositext::Validation::Content.new(
      {:primary => ['_', '_']}, {}
    )
  }

end
