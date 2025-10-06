module RLE
  def self.rle_encode(str)
    return "" if str.empty?
    result = String.new
    i = 0
    len = str.length
    while i < len
      char = str[i]
      count = 1
      while i + count < len && str[i + count] == char
        count += 1
      end
      result << char << count.to_s
      i += count
    end
    result
  end

  def self.rle_decode(str)
    return "" if str.empty?
    result = String.new
    i = 0
    len = str.length
    while i < len
      char = str[i]
      i += 1
      num_start = i
      while i < len && str[i] =~ /\d/
        i += 1
      end
      count = str[num_start...i].to_i
      result << char * count
    end
    result
  end
end