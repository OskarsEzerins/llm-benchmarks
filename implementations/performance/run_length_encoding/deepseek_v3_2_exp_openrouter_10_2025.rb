module RLE
  def self.rle_encode(str)
    return "" if str.empty?

    encoded = []
    count = 1
    current_char = str[0]

    (1...str.length).each do |i|
      if str[i] == current_char
        count += 1
      else
        encoded << current_char << count.to_s
        current_char = str[i]
        count = 1
      end
    end

    encoded << current_char << count.to_s
    encoded.join
  end

  def self.rle_decode(str)
    return "" if str.empty?

    decoded = []
    i = 0

    while i < str.length
      char = str[i]
      i += 1
      
      count_str = ""
      while i < str.length && str[i].match?(/\d/)
        count_str << str[i]
        i += 1
      end
      
      count = count_str.empty? ? 1 : count_str.to_i
      decoded << char * count
    end

    decoded.join
  end
end