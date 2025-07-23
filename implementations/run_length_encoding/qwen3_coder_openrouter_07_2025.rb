module RLE
  def self.rle_encode(str)
    return "" if str.empty?
    
    result = ""
    current_char = str[0]
    count = 1
    
    (1...str.length).each do |i|
      if str[i] == current_char
        count += 1
      else
        result << current_char << count.to_s
        current_char = str[i]
        count = 1
      end
    end
    
    result << current_char << count.to_s
  end
  
  def self.rle_decode(str)
    return "" if str.empty?
    
    result = ""
    i = 0
    
    while i < str.length
      char = str[i]
      i += 1
      
      count_str = ""
      while i < str.length && str[i] =~ /\d/
        count_str << str[i]
        i += 1
      end
      
      count = count_str.to_i
      result << char * count
    end
    
    result
  end
end