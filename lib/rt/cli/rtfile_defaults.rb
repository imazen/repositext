# Sets defaults for RtFile. Override any method that requires customization
# in your own RtFile.
module Rtfile

  def say
    STDERR.puts "hello from default rt_file"
  end

end
