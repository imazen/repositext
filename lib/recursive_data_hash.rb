# Hash with following properties:
#
# * optimized for handling of deeply nested data structures
# * autovivification (you can access arbitrarily deeply nested keys and they will return a hash)
# * uninitialized keys with names :warnings, :errors, or :stats will return an array.
# * uninitialized keys with names :errors_count or :warnings_count will return a zero.
# * the `summarize` method transforms deeply nested hashes into shallow hashes
#   with aggregate count data.
class RecursiveDataHash < Hash

  def initialize
    super { |h,k|
      case k
      when :errors, :stats, :warnings
        # initialize collectors with empty Array
        h[k] = []
      when :errors_count, :stats_count, :warnings_count
        # initialize counters with zero
        h[k] = 0
      else
        # initialize everything else with an instance of self for turtles all the way down
        h[k] = self.class.new
      end
    }
  end

  # Aggregates error and warning counts into top level hash keys
  def summarize(collecting_hash = self.class.new, collecting_key = nil)
    self.inject(collecting_hash) { |m,(k,v)|
      if :errors == k
        m[collecting_key][:errors_count] += v.size
        m
      elsif :stats == k
        m[collecting_key][:stats_count] += v.size
        m
      elsif :warnings == k
        m[collecting_key][:warnings_count] += v.size
        m
      else
        v.summarize(m, collecting_key || k)
      end
    }
  end

end
