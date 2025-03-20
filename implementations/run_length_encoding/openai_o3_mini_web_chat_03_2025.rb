class RLE
  def self.rle_encode(str)
    return "" if str.empty?
    encoded = ""
    count = 1
    prev = str[0]
    (1...str.size).each do |i|
      if str[i] == prev
        count += 1
      else
        encoded << "#{prev}#{count}"
        prev = str[i]
        count = 1
      end
    end
    encoded << "#{prev}#{count}"
    encoded
  end

  def self.rle_decode(encoded)
    return "" if encoded.empty?
    decoded = ""
    i = 0
    while i < encoded.size
      char = encoded[i]
      i += 1
      num_str = ""
      while i < encoded.size && encoded[i] =~ /\d/
        num_str << encoded[i]
        i += 1
      end
      decoded << char * num_str.to_i
    end
    decoded
  end
end
