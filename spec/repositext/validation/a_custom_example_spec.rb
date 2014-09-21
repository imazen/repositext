require_relative '../../helper'
require 'repositext/validation/a_custom_example' # have to manually require this validation

describe Repositext::Validation::ACustomExample do

  include Repositext::SharedSpecBehaviors::Validations

  before {
    @common_validation = Repositext::Validation::ACustomExample.new(
      {:primary => ['_', '_']}, {}
    )
  }

end
