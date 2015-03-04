require 'tsort'

class Hash
  include TSort
    alias tsort_each_node each_key
    def tsort_each_child(node, &block)
      fetch(node).each(&block)
    end
end

x = {1=>[2, 3], 2=>[3], 3=>[], 4=>[]}.tsort
puts x