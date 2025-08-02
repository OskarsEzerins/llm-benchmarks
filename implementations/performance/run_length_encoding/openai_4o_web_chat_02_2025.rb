module RLE
  def self.rle_encode(str)
    return "" if str.empty?

    encoded = ""
    count = 1

    (1...str.length).each do |i|
      if str[i] == str[i - 1]
        count += 1
      else
        encoded << str[i - 1] + count.to_s
        count = 1
      end
    end

    encoded << str[-1] + count.to_s
    encoded
  end

  def self.rle_decode(str)
    return "" if str.empty?

    decoded = ""
    i = 0

    while i < str.length
      char = str[i]
      i += 1
      num_start = i

      while i < str.length && str[i] =~ /\d/
        i += 1
      end

      decoded << char * str[num_start...i].to_i
    end

    decoded
  end
end
