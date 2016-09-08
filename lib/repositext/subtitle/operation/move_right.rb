class Repositext
  class Subtitle
    class Operation

      # Represents a move right subtitle operation.
      #
      class MoveRight < Operation

        def inverse_operation
          Subtitle::Operation.new_from_hash(
            affectedStids: inverse_affected_stids,
            operationId: '',
            operationType: :move_left,
          )
        end

        # Returns affected stids for inverse operation
        def inverse_affected_stids
          affectedStids.map { |e|
            before, after = e.tmp_attrs[:after], e.tmp_attrs[:before]
            e.tmp_attrs[:before] = before
            e.tmp_attrs[:after] = after
            e
          }
        end

      end

    end
  end
end
