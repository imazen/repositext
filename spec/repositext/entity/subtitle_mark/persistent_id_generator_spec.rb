require_relative '../../../helper'

class Repositext
  class Entity
    class SubtitleMark
      describe PersistentIdGenerator do

        let(:inventory_file) {
          FileLikeStringIO.new('_path', "abcd\nefgh\n", 'r+')
        }

        let(:generator) { PersistentIdGenerator.new(inventory_file) }

        describe '#generate' do

          it "generates one new ID by default" do
            generator.generate.length.must_equal(1)
          end

          it "generates multiple new IDs if told so" do
            generator.generate(7).length.must_equal(7)
          end

        end

        describe '#compute_unique_spids' do

          it "returns a new spid" do
            generator.send(:compute_unique_spids, 1).length.must_equal(1)
          end

          it "stops after a certain number of attempts if it can't find a non-existing SPID" do
            # stub PersistentIdGenerator#exists? to always return true
            def generator.spid_exists_in_inventory_file?(_); true; end
            -> { generator.send(:compute_unique_spids, 1) }.must_raise(RuntimeError)
          end

        end

        describe "#add_spids_to_inventory" do

          it "adds spids to inventory file in alphabetical order" do
            generator.send(:add_spids_to_inventory, ['qrst', 'kmnp'])
            generator.inventory_file.rewind
            generator.inventory_file.read.must_equal("abcd\nefgh\nkmnp\nqrst\n")
          end

        end

        describe "#generate_spid" do

          it "returns a valid spid" do
            r = generator.send(:generate_spid)
            r.is_a?(String).must_equal(true)
            r.length.must_equal(4)
          end

        end

        describe "#spid_exists_in_inventory_file?" do

          it "returns true if spid exists in inventory file" do
            generator.send(:spid_exists_in_inventory_file?, 'abcd').must_equal(true)
          end

          it "returns false if spid doesn't exist in inventory file" do
            generator.send(:spid_exists_in_inventory_file?, 'aaaa').must_equal(false)
          end

        end

      end
    end
  end
end
