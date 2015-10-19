# Generates persistent IDs for subtitle marks.
# Guarantees uniqueness in language scope (i.e. no duplicates in a language)
#
# Stores an inventory of used IDs in inventory file to prevent duplicates when
# assigning new SPIDS. We store this inventory file only in the primary repo.
#
class Repositext
  class Subtitle
    class PersistentIdGenerator

      # Synchronize SPID generation so that we can guarantee uniqueness in
      # multithreaded contexts.
      LOCK = Mutex.new

      SPID_CHARS = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789'.freeze
      # SPID forbidden chars: iloIO01
      SPID_CHARS_LEN = SPID_CHARS.size

      attr_reader :inventory_file # for testing

      # @param inventory_file [IO] file that contains the inventory of
      #          existing SPIDs.
      #          Typically located at /data/subtitle_persistent_ids.txt
      #          Must exist and be opened with mode "r+"
      def initialize(inventory_file)
        @inventory_file = inventory_file
      end

      # Returns a new persistent ID that is guaranteed to be unique in the
      # scope of the repo. Also adds the new ID to the inventory file
      # @param count [Integer, optional] how many SPIDs to generate
      # @return [Array<String>] An array with the newly assigned SPIDs
      def generate(count=1)
        spids = nil
        LOCK.synchronize do
          spids = compute_unique_spids(count)
          add_spids_to_inventory(spids)
        end
        spids
      end

    protected

      # Returns count spids that is guaranteed to be unique
      # @param count [Integer]
      def compute_unique_spids(count)
        overflow_count = 0
        new_spids = []
        while new_spids.length < count do
          spid = generate_spid
          raise RuntimeError.new("Infinite loop")  if (overflow_count += 1) > (count * 5)
          next  if spid_exists_in_inventory_file?(spid) || new_spids.include?(spid)
          new_spids << spid
        end
        new_spids
      end

      # Adds spids_to_add to the inventory of spids to guarantee uniqueness.
      # Keeps SPIDs sorted alphabetically, one per line.
      # @param spids_to_add [Array<String>]
      def add_spids_to_inventory(spids_to_add)
        @inventory_file.rewind
        existing_spids = @inventory_file.read.split("\n").compact
        @inventory_file.rewind
        # OPTIMIZE: We could use Array#bsearch to insert spids_to_add in the
        # correct spots to not have to sort again. Go from O(N) to O(log(N)).
        # Do this only if it turns out to cause significant delay.
        @inventory_file.write(
          (existing_spids + spids_to_add).uniq.sort.join("\n") + "\n"
        )
        @inventory_file.flush
      end

      # Generates an spid, may be a duplicate of an already existing one.
      # Examples:
      #   * a4AD
      #   * Z7w3
      #   * mJUK
      def generate_spid
        4.times.map { SPID_CHARS[rand(SPID_CHARS_LEN)] }.join
      end

      # Returns true if spid already exists in inventory file
      def spid_exists_in_inventory_file?(spid)
        # Lazily memoizes contents of inventory_file to make it faster.
        # We can't read the file until we have the LOCK. That precludes
        # initialization of this class with the contents of the file instead
        # of the file handle.
        @spids_from_inventory_file ||= (
          @inventory_file.rewind
          @inventory_file.read.split("\n")
        )
        !!@spids_from_inventory_file.bsearch { |e|
          if e < spid
            # go higher
            1
          elsif e > spid
            # go lower
            -1
          else
            # hit
            0
          end
        }
      end

    end
  end
end
