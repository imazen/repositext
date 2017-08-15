require_relative '../helper'

describe Hash do

  describe '#merge_recursive' do
    [
      [
        "Simple case",
        { a: 1, b: 2 },
        { a: 2, b: 2 },
        { a: 2, b: 2 },
      ],
      [
        "Two levels deep nested",
        { :a => { :b => { :c => "d" } } },
        { :a => { :b => { :x => "y" } } },
        { :a => { :b => { :c => "d", :x => "y" } } },
      ],
    ].each do |(description, h1, h2, xpect)|
      it description do
        h1.merge_recursive(h2).must_equal(xpect)
      end
    end
  end

end
