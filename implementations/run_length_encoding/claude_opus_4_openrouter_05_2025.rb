module RLE
  def self.rle_encode(str)
    return "" if str.empty?
    
    result = []
    chars = str.chars
    i = 0
    
    while i < chars.length
      char = chars[i]
      count = 1
      
      while i + count < chars.length && chars[i + count] == char
        count += 1
      end
      
      result << char << count.to_s
      i += count
    end
    
    result.join
  end
  
  def self.rle_decode(str)
    return "" if str.empty?
    
    result = []
    i = 0
    
    while i < str.length
      char = str[i]
      i += 1
      
      num_str = ""
      while i < str.length && str[i] =~ /\d/
        num_str << str[i]
        i += 1
      end
      
      count = num_str.to_i
      result << char * count
    end
    
    result.join
  end
end