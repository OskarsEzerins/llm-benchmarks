module RLE
  def self.rle_encode(str)
    return '' if str.empty?
    result = ''.dup
    prev = str[0]
    count = 1
    str.each_char.with_index(1) do |char, _|
      if char == prev
        count += 1
      else
        result << prev << count.to_s
        prev = char
        count = 1
      end
    end
    result << prev << count.to_s
  end

  def self.rle_decode(str)
    return '' if str.empty?
    result = ''.dup
    i = 0
    len = str.length
    while i < len
      char = str[i]
      i += 1
      j = i
      j += 1 while j < len && str[j] >= '0' && str[j] <= '9'
      count = str[i...j].to_i
      result << char * count
      i = j
    end
    result
  end
end