module RLE
  def self.rle_encode(str)
    return "" if str.empty?
    
    encoded = []
    current_char = str[0]
    count = 1
    
    (1...str.length).each do |i|
      if str[i] == current_char
        count += 1
      else
        encoded << "#{current_char}#{count}"
        current_char = str[i]
        count = 1
      end
    end
    
    encoded << "#{current_char}#{count}"
    encoded.join
  end

  def self.rle_decode(encoded_str)
    return "" if encoded_str.empty?
    
    decoded = []
    i = 0
    
    while i < encoded_str.length
      char = encoded_str[i]
      i += 1
      
      count_str = ""
      while i < encoded_str.length && encoded_str[i] =~ /[0-9]/
        count_str << encoded_str[i]
        i += 1
      end
      
      count = count_str.to_i
      decoded << char * count
    end
    
    decoded.join
  end
end