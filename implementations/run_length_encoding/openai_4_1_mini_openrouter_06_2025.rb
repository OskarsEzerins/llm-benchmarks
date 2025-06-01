module RLE
  def self.rle_encode(str)
    return "" if str.empty?
    result = []
    count = 1
    prev = str[0]
    str.each_char.drop(1).each do |char|
      if char == prev
        count += 1
      else
        result << prev << count.to_s
        prev = char
        count = 1
      end
    end
    result << prev << count.to_s
    result.join
  end

  def self.rle_decode(str)
    return "" if str.empty?
    result = []
    i = 0
    while i < str.length
      char = str[i]
      i += 1
      count_start = i
      while i < str.length && str[i] =~ /\d/
        i += 1
      end
      count = str[count_start...i].to_i
      result << char * count
    end
    result.join
  end
end