require_relative '../../helper'

describe Kramdown::Converter::LatexRepositext do

  it '' do
    c = Kramdown::Converter::LatexRepositext.send(:new, '_', {})
    c.send(:post_process_latex_body, '').must_equal ''
  end

end
