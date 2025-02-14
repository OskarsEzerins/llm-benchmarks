class LRUCache
class Node
attr_accessor :key , :val , :prv , :nxt

def initialize(key = nil, val = nil)
  @key = key
  @val = val
  @prv = nil
  @nxt = nil
end
end

def initialize(capacity)
@capacity = capacity
@hash = {}
@head = Node.new
@tail = Node.new
@head.nxt = @tail
@tail.prv = @head
end

def get(key)
node = @hash[key]
return nil unless node


remove_node(node)
add_to_front(node)
node.val
end

def put(key, value)
if @hash.key?(key)
node = @hash[key]
node.val = value
remove_node(node)
add_to_front(node)
else
if @hash.size >= @capacity
lru_node = @tail.prv
remove_node(lru_node)
@hash.delete(lru_node.key)
end


  new_node = Node.new(key, value)
  @hash[key] = new_node
  add_to_front(new_node)
end
end

private

def remove_node(node)
node.prv.nxt = node.nxt
node.nxt.prv = node.prv
end

def add_to_front(node)
node.prv = @head
node.nxt = @head.nxt
@head.nxt.prv = node
@head.nxt = node
end
end
