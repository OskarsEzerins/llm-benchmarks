module RLE
  def self.rle_encode(str)
    return "" if str.empty?
    result = []
    prev = str[0]
    count = 1
    (1...str.length).each do |i|
      if str[i] == prev
        count += 1
      else
        result << prev << count.to_s
        prev = str[i]
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
      num_str = ""
      while i < str.length && str[i].match?(/\d/)
        num_str << str[i]
        i += 1
      end
      count = num_str.to_i
      result << (char * count)
    end
    result.join
  end
end