module Hamming
  # TODO: Add Chunk class to separate logic and satisfy SOLID
  class Coder
    attr_reader :check_bits, :chunk_length

    def initialize(message, chunk_length)
      @chunk_length = chunk_length.to_i
      @check_bits = calc_check_bits
      @message = message
      check_user_values
      @binary_message = message_to_binary
    end

    # Transfer plain text to encoded binary
    # @return String
    def encode
      encoded_message = ''
      @binary_message.chars.each_slice(@chunk_length) do |chunk|
        chunk = chunk.join
        chunk_bin = append_check_bits(chunk)
        encoded_message += chunk_bin
      end

      encoded_message
    end

    # Transfer binary text to the original with fixing errors option
    # @return String
    def decode(encoded, fix_errors = false)
      # FIXME: move clean_chunks iteration outside of method
      decoded_message = ''
      fixed_encodes = []
      encoded.chars.each_slice(@chunk_length + @check_bits.size) do |chunk|
        chunk = chunk.join
        chunk = check_and_fix_error(chunk) if fix_errors
        fixed_encodes << chunk
      end

      clean_chunks = fixed_encodes.map { |chunk| exclude_check_bits(chunk) }
      clean_chunks.each do |chunk|
        clean_chars = []
        chunk.size.times { |i| clean_chars << chunk[i..i + 7] if (i % 8).zero? }
        clean_chars.map { |char| decoded_message += char.to_i(2).chr }
      end

      decoded_message
    end

    # Randomly change bits in input message
    # @return String
    def add_errors(message)
      msg_with_error = ''
      chunk_size = @chunk_length + @check_bits.size
      message.chars.each_slice(chunk_size) do |chunk|
        chunk = chunk.join
        random_bit = rand(1..chunk.size)
        deleted_char = chunk.slice!(random_bit - 1).to_i
        chunk.insert(random_bit - 1, (deleted_char ^ 1).to_s)
        msg_with_error += chunk
      end

      msg_with_error
    end

    # Return the difference in strings comparing each bit
    # @return Array
    def message_difference(message, other)
      message.split('').zip(other.split('')).map.with_index do |message_chars, index|
        index if message_chars.first != message_chars.last
      end.compact
    end

    private

    # Get info about check bits from chunk
    # @return Hash
    def check_bits_info(chunk)
      check_bits = {}
      chunk.each_char.with_index(1) do |char, index|
        check_bits[index] = char.to_i if @check_bits.include?(index)
      end

      check_bits
    end

    # Search for invalid bits and replace them by valid ones
    # @return String
    def check_and_fix_error(chunk)
      # FIXME: Separate logic between calculation and results iteration
      check_bits_encoded = check_bits_info(chunk)
      check_item = exclude_check_bits(chunk)
      check_item = append_check_bits(check_item)
      check_bits = check_bits_info(check_item)
      if check_bits_encoded != check_bits
        invalid_bits = []
        check_bits_encoded.each { |bit, value| invalid_bits << bit if check_bits[bit] != value }
        num_bit = invalid_bits.sum
        deleted_char = chunk.slice!(num_bit - 1).to_i
        chunk.insert(num_bit - 1, (deleted_char ^ 1).to_s)
      end

      chunk
    end

    # Remove check bits from chunk
    # @return String
    def exclude_check_bits(chunk)
      clean_value_bin = ''
      chunk.each_char.with_index(1) do |char, index|
        clean_value_bin += char unless @check_bits.include?(index)
      end

      clean_value_bin
    end

    # Add to chunk empty('0') bits
    # @return String
    def append_empty_check_bits(chunk)
      @check_bits.each { |bit| chunk.insert(bit - 1, '0') }

      chunk
    end

    # Get information about check bits from a chunk block
    # @return Hash
    def get_check_bits_data(chunk)
      check_bits_count_map = {}
      @check_bits.each { |bit| check_bits_count_map[bit] = 0 }
      chunk.each_char.with_index(1) do |char, index|
        if char == '1'
          # FIXME: Move condition body outside of method
          bin_chars = index.to_s(2).rjust(8, '0').split('').reverse
          degrees = bin_chars.map.with_index { |bin, i| 2**i if bin == '1' }.compact
          degrees.each { |degree| check_bits_count_map[degree] += 1 }
        end
      end
      check_bits_value_map = {}
      check_bits_count_map.each do |check_bit, count|
        check_bits_value_map[check_bit] = (count % 2).zero? ? 0 : 1
      end

      check_bits_value_map
    end

    # Set check bits value
    # @return String
    def append_check_bits(chunk)
      value_bin = append_empty_check_bits(chunk)
      check_bits_data = get_check_bits_data(value_bin)
      check_bits_data.each do |check_bit, bit_value|
        value_bin.slice!(check_bit - 1)
        value_bin.insert(check_bit - 1, bit_value.to_s)
      end

      value_bin
    end

    # Convert UTF-8 text to binary
    # @return String
    def message_to_binary
      @message.chars.map { |char| char.unpack('B*') }.flatten.join
    end

    # Iterate over chunk length and get check bits instance variable
    # @return Array
    def calc_check_bits
      bits = []
      @chunk_length.times do |chunk_index|
        bit = 2**chunk_index
        bits << bit if bit <= @chunk_length
      end

      bits
    end

    # STDIN params validation
    # @return nil || RuntimeError
    def check_user_values
      chunk_bits_err = 'Chunk length must be divided by 8'
      msg_err = "Message length must be divided by #{@chunk_length}"

      raise chunk_bits_err unless (@chunk_length % 8).zero?
      raise msg_err unless (@message.size * 8 % @chunk_length).zero?
    end
  end
end

if $PROGRAM_NAME == __FILE__
  msg = 'Usage: "ruby hamming.rb secret_word chunk_length"'
  return puts msg if ARGV.size.zero?

  message, chunk_length = ARGV
  coder = Hamming::Coder.new(message, chunk_length)
  puts "Chunk Length: #{coder.chunk_length}"
  puts "Check Bits: #{coder.check_bits}"
  encoded = coder.encode
  puts "Encoded data: #{encoded}"
  decoded = coder.decode(encoded)
  puts "Decoding result: #{decoded}"
  encoded_with_error = coder.add_errors(encoded)
  puts "Add some errors to encoded data: #{encoded_with_error}"
  differences = coder.message_difference(encoded, encoded_with_error)
  puts "Errors detected at bit positions: #{differences}"
  decoded_with_errors = coder.decode(encoded_with_error)
  puts 'Decoding without fix errors flag:' + decoded_with_errors
  decoded_without_errors = coder.decode(encoded_with_error, true)
  puts "Decoding with fix errors flag: #{decoded_without_errors}"
end
