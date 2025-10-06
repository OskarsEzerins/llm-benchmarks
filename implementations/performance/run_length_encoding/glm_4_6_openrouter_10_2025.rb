class RLE
  def self.rle_encode(str)
    return "" if str.empty?

    encoded = []
    current_char = str[0]
    count = 1

    str[1..-1].each_char do |char|
      if char == current_char
        count += 1
      else
        encoded << "#{current_char}#{count}"
        current_char = char
        count = 1
      end
    end
    encoded << "#{current_char}#{count}"

    encoded.join
  end

  def self.rle_decode(encoded_str)
    return "" if encoded_str.empty?

    decoded = []
    i = 0
    len = encoded_str.length

    while i < len
      char = encoded_str[i]
      i += 1
      num_str = ""

      while i < len && encoded_str[i] =~ /\d/
        num_str << encoded_str[i]
        i += 1
      end

      count = num_str.to_i
      decoded << char * count
    end

    decoded.join
  end
end