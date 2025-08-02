module RLE
  def self.rle_encode(input)
    return "" if input.empty?
    
    result = String.new(capacity: input.length)
    count = 1
    current_char = input[0]
    
    (1...input.length).each do |i|
      if input[i] == current_char
        count += 1
      else
        result << current_char << count.to_s
        current_char = input[i]
        count = 1
      end
    end
    
    result << current_char << count.to_s
    result
  end

  def self.rle_decode(input)
    return "" if input.empty?
    
    result = String.new(capacity: input.length * 2)
    chars = input.scan(/([A-Z])(\d+)/)
    
    chars.each do |char, count|
      result << char * count.to_i
    end
    
    result
  end
end