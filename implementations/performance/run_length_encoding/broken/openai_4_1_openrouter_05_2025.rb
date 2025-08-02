module RLE
  def self.rle_encode(str)
    return "" if str.empty?
    result = []
    prev_char = str[0]
    count = 1
    str.each_char.with_index(1) do |char, idx|
      if char == prev_char
        count += 1
      else
        result << prev_char << count.to_s
        prev_char = char
        count = 1
      end
    end
    result << prev_char << count.to_s
    result.join
  end

  def self.rle_decode(str)
    return "" if str.empty?
    result = []
    i = 0
    n = str.length
    while i < n
      char = str[i]
      i += 1
      count_str = ""
      while i < n && str[i] >= '0' && str[i] <= '9'
        count_str << str[i]
        i += 1
      end
      count = count_str.to_i
      result << char * count
    end
    result.join
  end
end