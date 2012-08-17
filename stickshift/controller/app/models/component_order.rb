require 'tsort'

# Helper class to perform topological sort on a list of components based on order specified in
# in the cartridge manifests.
# @see http://www.ruby-doc.org/stdlib-1.9.3/libdoc/tsort/rdoc/TSort.html
class ComponentOrder < Hash
  include TSort
  alias tsort_each_node each_key
  def tsort_each_child(node, &block)
    fetch(node).each(&block)
  end

  # Add components from cartridge manifest into hash to t-sort
  def add_component_order(order=[])
    order.each_index do |i|
      self[order[i]] = [] if self[order[i]].nil?
      self[order[i]] += order[0..(i-1)] if i != 0
    end
  end
end
