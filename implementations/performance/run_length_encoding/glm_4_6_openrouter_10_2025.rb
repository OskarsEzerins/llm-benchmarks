module RLE
  def self.rle_encode(str)
    return '' if str.empty?
    result = []
    prev = nil
    count = 0
    str.each_char do |ch|
      if prev.nil?
        prev = ch
        count = 1
      elsif ch == prev
        count += 1
      else
        result << prev << count.to_s
        prev = ch
        count = 1
      end
    end
    result << prev << count.to_s
    result.join
  end

  def self.rle_decode(encoded)
    return '' if encoded.empty?
    result = []
    i = 0
    n = encoded.length
    while i < n
      char = encoded[i]
      i += 1
      count_str = ''
      while i < n && encoded[i] =~ /\d/
        count_str << encoded[i]
        i += 1
      end
      count = count_str.empty? ? 1 : count_str.to_i
      result << char * count
    end
    result.join
  end
end