module RLE
  def self.rle_encode(str)
    return "" if str.empty?
    encoded = ""
    count = 1
    prev = str[0]
    str[1..-1].each_char do |c|
      if c == prev
        count += 1
      else
        encoded << prev << count.to_s
        prev = c
        count = 1
      end
    end
    encoded << prev << count.to_s
    encoded
  end

  def self.rle_decode(encoded)
    return "" if encoded.empty?
    decoded = ""
    i = 0
    while i < encoded.size
      char = encoded[i]
      i += 1
      num = ""
      while i < encoded.size && encoded[i] =~ /\d/
        num << encoded[i]
        i += 1
      end
      decoded << (char * num.to_i)
    end
    decoded
  end
end
