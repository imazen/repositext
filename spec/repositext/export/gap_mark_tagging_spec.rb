require_relative '../../helper'

describe Repositext::Export::GapMarkTagging do

  describe 'export' do
    [
      ["no change", "no change"],
      [
        "^^^ {: .rid}\n\n# Header\n\n@%*1*{: .pn} word1 word2 word3\n{: .class}\n",
        " Header\n\n%1 word1 word2 word3\n{: .class}\n",
      ],
    ].each do |txt, xpect|
      it "handles #{ txt.inspect }" do
        Repositext::Export::GapMarkTagging.export(txt).result.must_equal(xpect)
      end
    end
  end

  describe 'post_process' do
    [
      ["no change", "no change"],
      ["span IALs are removed{: .class}", "span IALs are removed"],
      ["(underscore placeholder)s are processed", "_s are processed"],
      ["# header hash marks are removed", " header hash marks are removed"],
      ["### header hash marks are removed", " header hash marks are removed"],
      ["block IALs are preserved\n{: .class}\n", "block IALs are preserved\n{: .class}\n"],
      ["%gap marks are preserved", "%gap marks are preserved"],
    ].each do |txt, xpect|
      it "handles #{ txt.inspect }" do
        Repositext::Export::GapMarkTagging.post_process(txt).must_equal(xpect)
      end
    end
  end

  describe 'pre_process' do
    [
      ["no change", "no change"],
      ["para\n{: .normal_pn}", "para\n{: .normal(underscore placeholder)pn}"],
    ].each do |txt, xpect|
      it "handles #{ txt.inspect }" do
        Repositext::Export::GapMarkTagging.pre_process(txt).must_equal(xpect)
      end
    end
  end

  describe 'suspend_unwanted_tokens' do
    # NOTE: can't have underscore in the test cases, they will be removed as :em tokens
    [
      ["%gap marks are preserved", "%gap marks are preserved"],
      ["# headers are preserved", "# headers are preserved"],
      ["block IALs are preserved\n{: .class}\n", "block IALs are preserved\n{: .class}\n"],
      ["span IALs are preserved{: .class}", "span IALs are preserved{: .class}"],
      ["@subtitle marks are removed", "subtitle marks are removed"],
      ["^^^ {: .rid}\n\nrecord marks are removed", "\nrecord marks are removed"],
      ["*ems* are _removed_", "ems are removed"],
    ].each do |txt, xpect|
      it "handles #{ txt.inspect }" do
        Repositext::Export::GapMarkTagging.suspend_unwanted_tokens(txt).must_equal(xpect)
      end
    end
  end

end
