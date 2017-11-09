require_relative '../helper'

class Repositext
  describe Cli do

    it "defines RtfileError" do
      Cli::RtfileError.class.must_equal Class
    end

    it "prints help when invoked without subcommand or argument" do
      out = capture_io { Cli.start(['--rtfile', '/path/to/rtfile', '--content-type-name', 'general']) }.join
      out.must_match(/\[COMMAND\]/)
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
          out = capture_io {
            Cli.start([command, 'test', '--rtfile', '/path/to/Rtfile', '--content-type-name', nil])
          }.join.strip
          out.must_include "#{ command }_test"
        end
      end
    end

    describe 'Higher level commands' do
      %w[
        export
        import
      ].each do |command|
        it "responds to '#{ command }'" do
          out = capture_io {
            Cli.start([command, 'test', '--rtfile', '/path/to/Rtfile', '--content-type-name', nil, '--skip-git-up-to-date-check'])
          }.join.strip
          out.must_include "#{ command }_test"
        end
      end
    end

    describe 'config' do
      # def config
      #   @config ||= Cli::Config.new
      # end
    end

  end
end

      # TODO: Put these specs in the right place.
      # describe '.find_rtfile' do
      #   it "finds Rtfile in current directory" do
      #     FileUtils.cd '/'
      #     FileUtils.touch 'Rtfile'
      #     klass.find_rtfile.must_equal '/Rtfile'
      #   end

      #   it "finds Rtfile in ancestor directory" do
      #     p = '/path1/path2'
      #     FileUtils.mkdir_p p
      #     FileUtils.cd '/path1'
      #     FileUtils.touch 'Rtfile'
      #     FileUtils.cd 'path2'
      #     klass.find_rtfile.must_equal '/path1/Rtfile'
      #   end

      #   it "returns nil if no Rtfile can be found" do
      #     klass.find_rtfile.must_equal nil
      #   end
      # end
