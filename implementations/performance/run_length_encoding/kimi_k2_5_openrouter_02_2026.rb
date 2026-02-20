module RLE
  def self.rle_encode(str)
    return "" if str.empty?
    
    result = String.new
    current = str[0]
    count = 1
    i = 1
    length = str.length
    
    while i < length
      if str[i] == current
        count += 1
      else
        result << current << count.to_s
        current = str[i]
        count = 1
      end
      i += 1
    end
    
    result << current << count.to_s
    result
  end
  
  def self.rle_decode(str)
    return "" if str.empty?
    
    result = String.new
    i = 0
    length = str.length
    
    while i < length
      char = str[i]
      i += 1
      count = 0
      while i < length && str[i] >= '0' && str[i] <= '9'
        count = count * 10 + (str[i].ord - 48)
        i += 1
      end
      result << (char * count)
    end
    
    result
  end
end