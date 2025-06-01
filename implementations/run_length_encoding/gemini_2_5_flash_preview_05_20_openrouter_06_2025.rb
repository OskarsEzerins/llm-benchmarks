module RLE
  def self.rle_encode(input_string)
    return "" if input_string.empty?

    encoded_string = String.new
    current_char = ''
    count = 0

    input_string.each_char do |char|
      if char == current_char
        count += 1
      else
        if count > 0
          encoded_string << current_char
          encoded_string << count.to_s
        end
        current_char = char
        count = 1
      end
    end

    encoded_string << current_char
    encoded_string << count.to_s

    encoded_string
  end

  def self.rle_decode(encoded_string)
    return "" if encoded_string.empty?

    decoded_string = String.new
    i = 0
    while i < encoded_string.length
      char = encoded_string[i]
      i += 1
      count_str = String.new
      while i < encoded_string.length && encoded_string[i] =~ /\d/
        count_str << encoded_string[i]
        i += 1
      end
      count = count_str.to_i
      decoded_string << char * count
    end
    decoded_string
  end
end