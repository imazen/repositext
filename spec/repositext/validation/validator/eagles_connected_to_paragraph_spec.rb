require_relative '../../../helper'

class Repositext
  class Validation
    class Validator

      describe EaglesConnectedToParagraph do

        describe '#eagles_connected_to_paragraph?' do

          it 'exits early on files that contain no eagle' do
            r_file = get_r_file(contents: 'text without eagle')
            v = EaglesConnectedToParagraph.new(r_file, '_', '_', {})
            v.send(
              :eagles_connected_to_paragraph?,
              r_file
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
              r_file = get_r_file(contents: test_string)
              v = EaglesConnectedToParagraph.new(r_file, '_', '_', {})
              v.send(
                :find_disconnected_eagles,
                r_file
              ).must_equal(xpect)
            end
          end

        end

      end

    end
  end
end
