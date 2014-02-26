require 'repositext/cli'
require_relative '../helper'

describe Repositext::Cli do

  it "prints help when invoked without subcommand or argument" do
    out = capture_io { Repositext::Cli.start(['--rtfile', nil]) }.join
    puts out
    out.must_match /Commands:\n/
  end

end
