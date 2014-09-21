require_relative '../../helper'

describe Repositext::Validation::SubtitlePostImport do

  include Repositext::SharedSpecBehaviors::Validations

  before {
    @common_validation = Repositext::Validation::SubtitlePostImport.new(
      {:primary => ['_', '_']}, {}
    )
  }

end
