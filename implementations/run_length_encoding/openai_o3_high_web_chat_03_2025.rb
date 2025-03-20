module RLE
  def self.rle_encode(str)
    return "" if str.empty?
    result = ""
    count = 1
    prev = str[0]
    (1...str.size).each do |i|
      if str[i] == prev
        count += 1
      else
        result << prev << count.to_s
        prev = str[i]
        count = 1
      end
    end
    result << prev << count.to_s
  end

  def self.rle_decode(str)
    return "" if str.empty?
    result = ""
    i = 0
    while i < str.size
      char = str[i]
      i += 1
      count_start = i
      i += 1 while i < str.size && str[i] =~ /\d/
      count = str[count_start...i].to_i
      result << (char * count)
    end
    result
  end
end
