module RLE
  def self.rle_encode(str)
    return "" if str.empty?
    result = +""
    last = str[0]
    count = 1
    str[1..-1].each_char do |char|
      if char == last
        count += 1
      else
        result << last << count.to_s
        last = char
        count = 1
      end
    end
    result << last << count.to_s
  end

  def self.rle_decode(str)
    return "" if str.empty?
    result = +""
    str.scan(/(.)(\d+)/) { |char, num| result << char * num.to_i }
    result
  end
end
