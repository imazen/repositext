class Repositext
  module SharedSpecBehaviors
    module Validations

      # Expects @common_validation to be initialized, like so:
      # before {
      #   @common_validation = Repositext::Validation::ACustomExample.new(
      #     {:primary => ['_', '_']}, {}
      #   )
      # }
      it 'responds to #run_list' do
        @common_validation.must_respond_to(:run_list)
      end

    end
  end
end
