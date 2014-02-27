require 'repositext/cli'
require_relative '../helper'

describe Repositext::Cli do

  it "defines RtfileError" do
    Repositext::Cli::RtfileError.class.must_equal Class
  end

  it "prints help when invoked without subcommand or argument" do
    out = capture_io { Repositext::Cli.start(['--rtfile', nil]) }.join
    out.must_match /Commands:\n/
  end

  describe 'class_options' do
  end

  describe 'basic commands' do
    %w[
      compare
      convert
      fix
      init
      merge
      sync
      validate
    ].each do |command|
      it "responds to '#{ command }'" do
        out = capture_io { Repositext::Cli.start([command, 'test', '--rtfile', nil]) }.join.strip
        out.must_equal "#{ command }_test"
      end
    end
  end

  describe 'Higher level commands' do
    %w[
      export
      import
    ].each do |command|
      it "responds to '#{ command }'" do
        out = capture_io { Repositext::Cli.start([command, 'test', '--rtfile', nil]) }.join.strip
        out.must_equal "#{ command }_test"
      end
    end
  end

  describe 'config' do
    # def config
    #   @config ||= Cli::Config.new
    # end
  end

end
