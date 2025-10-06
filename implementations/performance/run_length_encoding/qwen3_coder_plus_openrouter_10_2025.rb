module RLE
  def self.rle_encode(string)
    return "" if string.empty?
    
    result = ""
    current_char = string[0]
    count = 1
    
    (1...string.length).each do |i|
      if string[i] == current_char
        count += 1
      else
        result << current_char << count.to_s
        current_char = string[i]
        count = 1
      end
    end
    
    result << current_char << count.to_s
  end
  
  def self.rle_decode(string)
    return "" if string.empty?
    
    result = ""
    i = 0
    
    while i < string.length
      char = string[i]
      i += 1
      
      count_str = ""
      while i < string.length && string[i] =~ /\d/
        count_str << string[i]
        i += 1
      end
      
      count = count_str.to_i
      result << char * count
    end
    
    result
  end
end