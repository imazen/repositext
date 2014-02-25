require 'repositext/rt'
require_relative '../helper'

describe Repositext::Rt do

  it "prints help when invoked without subcommand or argument" do
    out = capture_io { Repositext::Rt.start(['--rtfile', nil]) }.join
    puts out
    out.must_match /Commands:\n/
  end

end
