module RLE
  def self.rle_encode(str)
    return "" if str.empty?
    result = +""
    last = str[0]
    count = 1
    str[1..-1].each_char do |c|
      if c == last
        count += 1
      else
        result << last << count.to_s
        last = c
        count = 1
      end
    end
    result << last << count.to_s
  end

  def self.rle_decode(str)
    return "" if str.empty?
    result = +""
    str.scan(/(.)(\d+)/) do |char, cnt|
      result << char * cnt.to_i
    end
    result
  end
end
