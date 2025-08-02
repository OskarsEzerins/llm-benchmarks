module RLE
  def self.rle_encode(input)
    return "" if input.empty?
    
    result = ""
    count = 1
    
    (1...input.length).each do |i|
      if input[i] == input[i-1]
        count += 1
      else
        result << input[i-1] << count.to_s
        count = 1
      end
    end
    
    # Handle the last character
    result << input[-1] << count.to_s
    
    result
  end
  
  def self.rle_decode(input)
    return "" if input.empty?
    
    result = ""
    i = 0
    
    while i < input.length
      char = input[i]
      i += 1
      
      # Extract the count digits
      count_str = ""
      while i < input.length && input[i] =~ /\d/
        count_str << input[i]
        i += 1
      end
      
      count = count_str.to_i
      result << char * count
    end
    
    result
  end
end