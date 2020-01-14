# class to hold nodes in the huffman tree
class Node
  attr_accessor :val, :weight, :left, :right

  def initialize(val = '', weight = 0)
    @val = val
    @weight = weight
  end

  def children?
    @left || @right
  end
end

# class for priority nodes queue
class NodeQueue
  def initialize
    @queue = []
  end

  def enqueue(node)
    @queue << node
    @queue = @queue.sort_by { |el| [-el.weight, el.val.size] }
  end

  def dequeue
    @queue.pop
  end

  def size
    @queue.size
  end
end

class HuffmanTree
  def initialize(data)
    @freqs = build_frequencies(data)
    @root = build_root
  end

  def encode(data)
    data.downcase.split(//).inject('') do |code, char|
      code + encode_char(char)
    end
  end

  def decode(data)
    return @root.val unless @root.children?

    node = @root
    data.split(//).inject('') do |phrase, digit|
      node = digit.to_i.zero? ? node.left : node.right

      unless node.children?
        phrase += node.val
        node = @root
      end

      phrase
    end
  end

  private

  def encode_char(char)
    return '0' unless @root.children?

    node = @root
    coding = ''

    # we do a binary search, building the representation
    # of the character based on which branch we follow
    while node.val != char
      if node.right.val.include?(char)
        node, coding = append_value_to_char(:right, node, coding)
      else
        node, coding = append_value_to_char(:left, node, coding)
      end
    end

    coding
  end

  def append_value_to_char(way, node, char)
    if way == :right
      node = node.right
      char += '1'
    else
      node = node.left
      char += '0'
    end

    [node, char]
  end

  # Get frequency of each char in phrase
  def build_frequencies(phrase)
    frequency = Hash.new(0)
    phrase.downcase.split(//).each { |char| frequency[char] += 1 }

    frequency
  end

  # build huffmantree using the priority queue method
  def build_root
    queue = build_nodes
    until queue.size.zero?
      return queue.dequeue if queue.size == 1

      # dequeue two lightest nodes, create parent,
      # add children and enqueue newly created node
      node = Node.new
      node.right = queue.dequeue
      node.left = queue.dequeue
      node.val = node.left.val + node.right.val
      node.weight = node.left.weight + node.right.weight
      queue.enqueue(node)
    end
  end

  def build_nodes
    queue = NodeQueue.new
    @freqs.keys.each { |char| queue.enqueue(Node.new(char, @freqs[char])) }

    queue
  end
end

if $PROGRAM_NAME == __FILE__
  return puts 'Usage: "ruby huffman.rb your text data"' if ARGV.size.zero?

  data = ARGV.join(' ')
  tree = HuffmanTree.new(data)

  code = tree.encode(data)
  encoded_bits = code.scan(/\d{1,8}/)

  # STDOUT
  puts 'Original:'
  puts data
  puts "#{data.size} bytes"
  puts
  puts 'Encoded:'
  encoded_bits.each_slice(5) do |slice|
    puts slice.join(' ')
  end
  puts "#{encoded_bits.size} bytes"
  puts
  puts '%d percent compression' % (100.0 - (encoded_bits.size.to_f / data.size) * 100.0)
  puts
  puts 'Decoded:'
  puts tree.decode(code)
end
