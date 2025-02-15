module RLE
  def self.rle_encode(string)
    return "" if string.empty?

    encoded = ""
    count = 1
    (0...string.length).each do |i|
      if i + 1 < string.length && string[i] == string[i + 1]
        count += 1
      else
        encoded << string[i] << (count > 1 ? count.to_s : "")
        count = 1
      end
    end
    encoded
  end

  def self.rle_decode(string)
    return "" if string.empty?

    decoded = ""
    i = 0
    while i < string.length
      char = string[i]
      i += 1
      count_str = ""
      while i < string.length && string[i] =~ /[0-9]/
        count_str << string[i]
        i += 1
      end
      count = count_str.empty? ? 1 : count_str.to_i
      decoded << char * count
    end
    decoded
  end
end
