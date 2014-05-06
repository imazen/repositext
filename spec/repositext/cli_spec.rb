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
    describe '--rtfile' do
      # class_option :rtfile,
      #              :aliases => '-rt',
      #              :type => :string,
      #              :required => true,
      #              :desc => 'Specifies which Rtfile to use. Defaults to the closest Rtfile found in the directory hierarchy.'
    end
    describe '--input' do
      # class_option :input,
      #              :aliases => '-i',
      #              :type => :string,
      #              :desc => 'Specifies the input file pattern. Expects an absolute path pattern that can be used with Dir.glob.'
    end
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
