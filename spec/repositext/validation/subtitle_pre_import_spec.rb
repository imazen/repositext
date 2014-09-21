require_relative '../../helper'

describe Repositext::Validation::SubtitlePreImport do

  include Repositext::SharedSpecBehaviors::Validations

  before {
    @common_validation = Repositext::Validation::SubtitlePreImport.new(
      {:primary => ['_', '_']}, {}
    )
  }

end
