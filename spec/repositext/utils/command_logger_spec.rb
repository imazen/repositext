require_relative '../../helper'

class Repositext
  class Utils
    describe CommandLogger do

      let(:output_dest){ StringIO.new }

      describe '#debug' do
        it "suppresses debug output by default" do
          cl = CommandLogger.new(output_destination: output_dest)
          cl.debug("This is a debug message")
          output_dest.string.must_equal("")
        end

        it "includes debug output if told" do
          cl = CommandLogger.new(
            min_level: :debug,
            output_destination: output_dest
          )
          cl.debug("This is a debug message")
          output_dest.string.must_equal("This is a debug message\n")
        end
      end

      describe '#info' do
        it "includes info output by default" do
          cl = CommandLogger.new(output_destination: output_dest)
          cl.info("This is an info message")
          output_dest.string.must_equal("This is an info message\n")
        end

        it "suppresses info output if told" do
          cl = CommandLogger.new(
            min_level: :warning,
            output_destination: output_dest
          )
          cl.debug("This is an info message")
          output_dest.string.must_equal("")
        end
      end

      describe '#warning' do
        it "includes and colorizes warning output by default" do
          cl = CommandLogger.new(output_destination: output_dest)
          cl.warning("This is a warning message")
          output_dest.string.must_equal("\e[38;5;214mThis is a warning message\e[0m\n")
        end
      end

      describe '#error' do
        it "includes and colorizes error output by default" do
          cl = CommandLogger.new(output_destination: output_dest)
          cl.error("This is an error message")
          output_dest.string.must_equal("\e[31mThis is an error message\e[0m\n")
        end
      end

      describe '#color_for_level' do
        [
          [:debug, nil],
          [:info, nil],
          [:warning, :orange],
          [:error, :red],
        ].each do |level, xpect|
          it "computes color for #{ level }" do
            cl = CommandLogger.new
            cl.send(:color_for_level, level).must_equal(xpect)
          end
        end
      end

      describe '#compute_color' do
        [
          [:debug, { colorize: true }, nil],
          [:debug, { color_override: :turquoise }, :turquoise],
          [:info, { colorize: true }, nil],
          [:warning, { colorize: true }, :orange],
          [:error, { colorize: true }, :red],
          [:error, { colorize: false }, nil],
        ].each do |level, attrs, xpect|
          it "computes color for #{ level }" do
            cl = CommandLogger.new
            cl.send(:compute_color, level, attrs).must_equal(xpect)
          end
        end
      end

    end
  end
end
