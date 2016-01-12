# Provides helper methods for testing Folio parser

# Wraps xml_fragment in infobase tags
# @param [String] xml_fragment
def wrap_in_xml_infobase(xml_fragment)
  %(<infobase>#{ xml_fragment }</infobase)
end

# Wraps xml_fragment in record tags
# @param [String] xml_fragment
def wrap_in_xml_record(xml_fragment)
  wrap_in_xml_infobase(%(
    <record class="NormalLevel" fullPath="/50000009/50130009/50130229" recordId="50130229">
      #{ xml_fragment }
    </record>)
  )
end

# Constructs a kramdown tree from data.
# CAUTION: Two trees will be connected if you use the same Kramdown::ElementRt
# objects to construct them.
# @param [Array<Array>] tuple: An array with first as the parent and
#     last as a single child or an array of children:
#     [root, [
#       [para, [
#         text1,
#         blank1,
#         [em, [text2]]
#       ]]
#     ]]
def construct_kramdown_rt_tree(data)
  parent, children = data
  parent_clone = parent.clone
  children.each do |child|
    case child
    when Array
      parent_clone.add_child(construct_kramdown_rt_tree(child))
    when Kramdown::ElementRt
      parent_clone.add_child(child.clone)
    else
      raise(ArgumentError.new("invalid child: #{ child.inspect }"))
    end
  end
  parent_clone
end
