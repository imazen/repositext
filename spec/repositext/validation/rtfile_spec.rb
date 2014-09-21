require_relative '../../helper'

describe Repositext::Validation::Rtfile do

  include Repositext::SharedSpecBehaviors::Validations

  before {
    @common_validation = Repositext::Validation::Rtfile.new(
      {:primary => ['_', '_']}, {}
    )
  }

end
