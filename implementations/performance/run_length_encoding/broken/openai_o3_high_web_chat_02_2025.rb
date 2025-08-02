module RLE
  def self.rle_encode(str)
    return "" if str.empty?
    result = []
    count = 1
    last = str[0]
    str.each_char.with_index do |c, i|
      next if i.zero?
      if c == last
        count += 1
      else
        result << "#{last}#{count}"
        last = c
        count = 1
      end
    end
    result << "#{last}#{count}"
    result.join
  end

  def self.rle_decode(encoded)
    return "" if encoded.empty?
    result = []
    encoded.scan(/(.)(\d+)/) { |char, num| result << char * num.to_i }
    result.join
  end
end
