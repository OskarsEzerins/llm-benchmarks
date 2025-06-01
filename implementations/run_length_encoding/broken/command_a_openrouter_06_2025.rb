module RLE
  def self.rle_encode(str)
    return "" if str.empty?

    encoded = +""
    count = 1

    (0...str.size).each do |i|
      if i + 1 < str.size && str[i] == str[i + 1]
        count += 1
      else
        encoded << str[i] << count.to_s
        count = 1
      end
    end

    encoded.to_s
  end

  def self.rle_decode(str)
    return "" if str.empty?

    decoded = +""
    i = 0

    while i < str.size
      char = str[i]
      count = str[i + 1].to_i
      decoded << char * count
      i += 2
    end

    decoded.to_s
  end
end