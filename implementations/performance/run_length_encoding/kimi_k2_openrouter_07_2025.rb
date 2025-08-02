module RLE
  def self.rle_encode(str)
    return "" if str.empty?
    
    result = []
    count = 1
    last_char = str[0]
    
    (1...str.length).each do |i|
      if str[i] == last_char
        count += 1
      else
        result << last_char
        result << count.to_s
        last_char = str[i]
        count = 1
      end
    end
    
    result << last_char
    result << count.to_s
    
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