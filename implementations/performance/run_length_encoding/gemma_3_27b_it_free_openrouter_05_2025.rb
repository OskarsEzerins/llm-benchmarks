module RLE
  def self.rle_encode(input_string)
    return "" if input_string.empty?

    encoded_string = ""
    count = 1
    current_char = input_string[0]

    (1...input_string.length).each do |i|
      if input_string[i] == current_char
        count += 1
      else
        encoded_string << current_char
        encoded_string << count.to_s
        current_char = input_string[i]
        count = 1
      end
    end

    encoded_string << current_char
    encoded_string << count.to_s

    encoded_string
  end

  def self.rle_decode(input_string)
    return "" if input_string.empty?

    decoded_string = ""
    i = 0

    while i < input_string.length
      char = input_string[i]
      i += 1

      count_str = ""
      while i < input_string.length && input_string[i].match?(/[0-9]/)
        count_str << input_string[i]
        i += 1
      end

      count = count_str.to_i

      decoded_string << char * count
    end

    decoded_string
  end
end