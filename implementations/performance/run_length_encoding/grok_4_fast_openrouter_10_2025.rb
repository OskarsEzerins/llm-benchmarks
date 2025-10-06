module RLE
  def self.rle_encode(str)
    return "" if str.empty?
    result = []
    current = str[0]
    count = 1
    (1...str.length).each do |i|
      if str[i] == current
        count += 1
      else
        result << current << count.to_s
        current = str[i]
        count = 1
      end
    end
    result << current << count.to_s
    result.join
  end

  def self.rle_decode(encoded)
    return "" if encoded.empty?
    result = String.new
    i = 0
    len = encoded.length
    while i < len
      char = encoded[i]
      i += 1
      num_str = ''
      while i < len && encoded[i] =~ /\d/
        num_str << encoded[i]
        i += 1
      end
      count = num_str.empty? ? 1 : num_str.to_i
      result << (char * count)
    end
    result
  end
end