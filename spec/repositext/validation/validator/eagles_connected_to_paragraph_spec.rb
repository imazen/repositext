require_relative '../../../helper'

class Repositext
  class Validation
    class Validator

      describe EaglesConnectedToParagraph do

        describe '#eagles_connected_to_paragraph?' do

          it 'exits early on files that contain no eagle' do
            v = EaglesConnectedToParagraph.new('_', '_', '_', {})
            v.send(
              :eagles_connected_to_paragraph?,
              'text without eagle'
            ).success.must_equal(true)
          end

        end

        describe '#find_disconnected_eagles' do

          [
            ['text without eagle', []],
            [" para1 with beginning eagle\n\nother para\n\nlast para with ending eagle\n\n", []],
            [" para1 with beginning eagle\n\nother para\n\n@\n\n", [['line 5', '@']]],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              v = EaglesConnectedToParagraph.new('_', '_', '_', {})
              v.send(
                :find_disconnected_eagles,
                test_string
              ).must_equal(xpect)
            end
          end

        end

      end

    end
  end
end
