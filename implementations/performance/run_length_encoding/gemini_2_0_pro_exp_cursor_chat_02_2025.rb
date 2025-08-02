module RLE
  def self.rle_encode(input)
    return "" if input.empty?

    encoded_string = ""
    current_char = input[0]
    char_count = 1

    index = 1
    while index < input.length
      if input[index] == current_char
        char_count += 1
      else
        encoded_string << current_char
        encoded_string << char_count.to_s
        current_char = input[index]
        char_count = 1
      end
      index += 1
    end

    encoded_string << current_char
    encoded_string << char_count.to_s
    encoded_string
  end

  def self.rle_decode(input)
    return "" if input.empty?

    decoded_string = ""
    index = 0

    while index < input.length
      current_char = input[index]
      index += 1
      count_string = ""

      while index < input.length && input[index] =~ /\d/
        count_string << input[index]
        index += 1
      end

      count = count_string.to_i
      decoded_string << current_char * count
    end

    decoded_string
  end
end
