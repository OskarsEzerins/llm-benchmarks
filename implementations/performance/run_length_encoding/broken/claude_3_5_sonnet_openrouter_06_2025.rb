module RLE
  def self.rle_encode(input)
    return "" if input.empty?
    
    result = String.new
    count = 1
    prev_char = input[0]
    
    (1...input.length).each do |i|
      if input[i] == prev_char
        count += 1
      else
        result << prev_char << count.to_s
        prev_char = input[i]
        count = 1
      end
    end
    
    result << prev_char << count.to_s
    result
  end

  def self.rle_decode(input)
    return "" if input.empty?
    
    result = String.new
    chars = input.scan(/([A-Z])(\d+)/)
    
    chars.each do |char, count|
      result << char * count.to_i
    end
    
    result
  end
end