module RLE
  def self.rle_encode(str)
    return "" if str.empty?
    encoded = []
    prev_char = str[0]
    count = 1
    (1...str.length).each do |i|
      if str[i] == prev_char
        count += 1
      else
        encoded << prev_char << count.to_s
        prev_char = str[i]
        count = 1
      end
    end
    encoded << prev_char << count.to_s
    encoded.join
  end

  def self.rle_decode(str)
    return "" if str.empty?
    decoded = []
    i = 0
    while i < str.length
      char = str[i]
      j = i + 1
      while j < str.length && str[j] =~ /\d/
        j += 1
      end
      count = str[(i + 1)...j].to_i
      decoded << char * count
      i = j
    end
    decoded.join
  end
end
