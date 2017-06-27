require_relative '../../helper'

class Repositext
  class Subtitle
    describe Operation do

      let(:deleteDefaultAttrs){
        {
          affected_stids: [
            {
              stid: "1234567",
              record_id: nil,
              before: "@word3 word4 word5",
              after: nil,
            },
          ],
          operation_id: '123',
          operation_type: :delete,
        }
      }
      let(:insertDefaultAttrs){
        {
          affected_stids: [
            {
              stid: "1234567",
              record_id: nil,
              before: nil,
              after: "@word3 word4 word5",
            },
          ],
          after_stid: "4567890",
          operation_id: '123',
          operation_type: :insert,
        }
      }
      let(:mergeDefaultAttrs){
        {
          affected_stids: [
            {
              stid: "2345678",
              record_id: nil,
              before: "@word1",
              after: "@word1 word2",
            },
            {
              stid: "5678901",
              record_id: nil,
              before: "@word2",
              after: nil,
            },
          ],
          operation_id: '123',
          operation_type: :merge,
        }
      }
      let(:moveLeftDefaultAttrs){
        {
          affected_stids: [
            {
              stid: "8901234",
              record_id: nil,
              before: "@word1 word2",
              after: "@word1",
            },
            {
              stid: "3456789",
              record_id: nil,
              before: "@word3 word4",
              after: "@word2 word3 word4",
            },
          ],
          operation_id: '123',
          operation_type: :move_left,
        }
      }
      let(:moveRightDefaultAttrs){
        {
          affected_stids: [
            {
              stid: "8901234",
              record_id: nil,
              before: "@word1 word2",
              after: "@word1 word2 word3",
            },
            {
              stid: "3456789",
              record_id: nil,
              before: "@word3 word4",
              after: "@word4",
            },
          ],
          operation_id: '123',
          operation_type: :move_left,
        }
      }
      let(:splitDefaultAttrs){
        {
          affected_stids: [
            {
              stid: "9012345",
              record_id: nil,
              before: "@word1 word2 word3 word4",
              after: "@word1 word2",
            },
            {
              stid: "1234567",
              record_id: nil,
              before: null,
              after: "@word3 word4",
            },
          ],
          operation_id: '123',
          operation_type: :split,
        }
      }

      describe '.from_hash and .to_hash (roundtrip)' do

        %w[
          deleteDefaultAttrs
          insertDefaultAttrs
          mergeDefaultAttrs
          moveLeftDefaultAttrs
          moveRightDefaultAttrs
        ].each do |attrs_name|
          it "handles #{ attrs_name }" do
            attrs = self.send(attrs_name)
            roundtrip_hash = Operation.new_from_hash(attrs).to_hash
            roundtrip_hash.must_equal(attrs)
          end
        end

      end

    end
  end
end
