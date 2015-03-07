require 'tsort'
require 'byebug'

class Hash
  include TSort
    alias tsort_each_node each_key
    def tsort_each_child(node, &block)
      fetch(node).each(&block)
    end
end

def top_sort hash
  hash.tsort
end

def findStrongTies(ties)
  tied = {}
  ties.each_key do |item|
    ties[item].each do |dependency|
      if( ties[dependency] != nil && ties[dependency].include?(item) )
        if !tied[item] then tied[item] = [] end
        tied[item].push dependency
      end
    end
  end
  tied
end

def cyclical( x )
  ties = findStrongTies( x.strongly_connected_components )
  ties = ties.flatten
  cyclical = []
  x.each_key do |key|
    cyclical.push
  end
  cyclical
end

def non_cyclical( x )
  cyclical = findStrongTies( x )
  puts cyclical
  non_cyclical = {}
  x.each_key do |key|
    if !cyclical.include?(key) then non_cyclical[key] = x[key] end
  end
  non_cyclical
end

def remove_non_keys x
  x.each_key do |key|
    cloned = []
    x[key].each do |n|
      if x[n]
        cloned.push( n )
      end
    end
    x[key] = cloned
  end
  x
end
