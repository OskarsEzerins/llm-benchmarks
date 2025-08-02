class RLE
  def self.rle_encode(str)
    return "" if str.empty?

    result = ""
    current_char = str[0]
    count = 1

    (1...str.length).each do |i|
      if str[i] == current_char
        count += 1
      else
        result << current_char << count.to_s
        current_char = str[i]
        count = 1
      end
    end

    result << current_char << count.to_s
    result
  end

  def self.rle_decode(encoded_str)
    return "" if encoded_str.empty?

    result = ""
    i = 0

    while i < encoded_str.length
      char = encoded_str[i]
      i += 1

      num_str = ""
      while i < encoded_str.length && encoded_str[i] =~ /\d/
        num_str << encoded_str[i]
        i += 1
      end

      count = num_str.to_i
      result << char * count
    end

    result
  end
end
