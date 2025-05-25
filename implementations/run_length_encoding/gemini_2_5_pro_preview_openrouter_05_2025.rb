module RLE
  def self.rle_encode(input_string)
    return "" if input_string.empty?

    encoded_parts = []
    current_char = input_string[0]
    count = 0

    input_string.each_char do |char|
      if char == current_char
        count += 1
      else
        encoded_parts << current_char
        encoded_parts << count.to_s
        current_char = char
        count = 1
      end
    end

    # Append the last run
    encoded_parts << current_char
    encoded_parts << count.to_s

    encoded_parts.join
  end

  def self.rle_decode(encoded_string)
    return "" if encoded_string.empty?

    decoded_parts = []
    i = 0
    while i < encoded_string.length
      char_to_repeat = encoded_string[i]
      i += 1

      num_str = ""
      while i < encoded_string.length && encoded_string[i] >= '0' && encoded_string[i] <= '9'
        num_str << encoded_string[i]
        i += 1
      end
      
      count = num_str.to_i
      # According to typical RLE, if a character appears, its count should be at least 1.
      # If num_str is empty (e.g. malformed RLE like "A" instead of "A1"),
      # count becomes 0, and char_to_repeat * 0 results in an empty string,
      # effectively skipping the character. This handles malformed cases gracefully.
      
      decoded_parts << (char_to_repeat * count)
    end

    decoded_parts.join
  end
end