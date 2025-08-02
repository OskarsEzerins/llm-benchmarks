module RLE
  def self.rle_encode(str)
    return "" if str.empty?
    result = []
    count = 1
    prev_char = str[0]
    (1...str.length).each do |i|
      if str[i] == prev_char
        count += 1
      else
        result << "#{prev_char}#{count}"
        prev_char = str[i]
        count = 1
      end
    end
    result << "#{prev_char}#{count}"
    result.join
  end

  def self.rle_decode(str)
    return "" if str.empty?
    result = []
    str.scan(/(\D)(\d+)/) do |char, num|
      result << (char * num.to_i)
    end
    result.join
  end
end
