class RLE
  def self.rle_encode(str)
    return "" if str.empty?
    result = []
    count = 1
    prev = str[0]
    str.each_char.drop(1).each do |ch|
      if ch == prev
        count += 1
      else
        result << prev << count.to_s
        prev = ch
        count = 1
      end
    end
    result << prev << count.to_s
    result.join
  end

  def self.rle_decode(str)
    return "" if str.empty?
    result = []
    chars = str.chars
    i = 0
    while i < chars.size
      char = chars[i]
      i += 1
      num_start = i
      while i < chars.size && chars[i] =~ /\d/
        i += 1
      end
      num = str[num_start...i].to_i
      result << char * num
    end
    result.join
  end
end
