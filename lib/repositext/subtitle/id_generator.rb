# Generates persistent IDs for subtitle marks.
# Guarantees uniqueness in language scope (i.e. no duplicates in a language)
#
# Stores an inventory of used IDs in inventory file to prevent duplicates when
# assigning new stidS. We store this inventory file only in the primary repo.
#

require 'set' # uses SortedSet for better performance

class Repositext
  class Subtitle
    class IdGenerator

      # Synchronize stid generation so that we can guarantee uniqueness in
      # multithreaded contexts.
      LOCK = Mutex.new

      STID_AVAILABLE_CHARS_COUNT = STID_CHARS.size

      attr_reader :inventory_file # for testing

      # @param inventory_file [IO] file that contains the inventory of
      #          existing stids.
      #          Typically located at /data/subtitle_ids.txt
      #          Must exist and be opened with mode "r+"
      def initialize(inventory_file)
        @inventory_file = inventory_file
      end

      # Returns a new persistent ID that is guaranteed to be unique in the
      # scope of the repo. Also adds the new ID to the inventory file
      # @param count [Integer, optional] how many stids to generate
      # @return [Array<String>] An array with the newly assigned stids
      def generate(count=1)
        stids = nil
        LOCK.synchronize do
          # Load existing stids after we locked the file
          @inventory_file.rewind
          @existing_stids = SortedSet.new(@inventory_file.read.split("\n"))
          stids = compute_unique_stids(count)
          add_stids_to_inventory(stids)
        end
        stids.to_a
      end

    protected

      # Returns `count` stids that are guaranteed to be unique in the scope of
      # `inventory_file`.
      # @param count [Integer]
      def compute_unique_stids(count)
        overflow_count = 0
        new_stids = SortedSet.new
        while new_stids.length < count do
          stid = generate_stid
          raise RuntimeError.new("Infinite loop")  if (overflow_count += 1) > (count * 5)
          next  if stid_exists_in_inventory_file?(stid) || new_stids.include?(stid)
          new_stids << stid
        end
        new_stids
      end

      # Adds stids_to_add to the inventory of stids to guarantee uniqueness.
      # Keeps stids sorted alphabetically, one per line.
      # @param stids_to_add [Array<String>]
      def add_stids_to_inventory(stids_to_add)
        new_stids = @existing_stids.merge(stids_to_add)
        @inventory_file.rewind
        @inventory_file.write(new_stids.to_a.join("\n") + "\n")
        @inventory_file.flush
      end

      # Generates an stid, may be a duplicate of an already existing one.
      # Examples:
      #   * a4AD
      #   * Z7w3
      #   * mJUK
      def generate_stid
        # start with non-zero digit
        stid = STID_CHARS[rand(STID_AVAILABLE_CHARS_COUNT)]
        # add remaining chars
        (STID_LENGTH - 1).times.each { stid << STID_CHARS[rand(STID_AVAILABLE_CHARS_COUNT)] }
        stid
      end

      # Returns true if stid already exists in inventory file
      def stid_exists_in_inventory_file?(stid)
        @existing_stids.include?(stid)
      end

    end
  end
end
