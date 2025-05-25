module RLE
  def self.rle_encode(input_string)
    return "" if input_string.empty?

    encoded_string = ""
    current_char = nil
    count = 0

    input_string.each_char do |char|
      if current_char.nil?
        current_char = char
        count = 1
      elsif char == current_char
        count += 1
      else
        encoded_string << current_char
        encoded_string << count.to_s
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

    decoded_string = ""
    i = 0
    while i < encoded_string.length
      char = encoded_string[i]
      i += 1
      count_str = ""
      while i < encoded_string.length && encoded_string[i] =~ /[0-9]/
        count_str << encoded_string[i]
        i += 1
      end
      
      count = count_str.empty? ? 1 : count_str.to_i
      decoded_string << char * count
    end

    decoded_string
  end
end