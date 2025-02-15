module RLE
  def self.rle_encode(input)
    return "" if input.empty?
    encoded = ""
    count = 1
    (1...input.length).each do |i|
      if input[i] == input[i - 1]
        count += 1
      else
        encoded << input[i - 1] << count.to_s
        count = 1
      end
    end
    encoded << input[-1] << count.to_s
    encoded
  end

  def self.rle_decode(input)
    return "" if input.empty?
    decoded = ""
    i = 0
    while i < input.length
      char = input[i]
      count = ""
      i += 1
      while i < input.length && input[i].match?(/\d/)
        count << input[i]
        i += 1
      end
      decoded << char * count.to_i
    end
    decoded
  end
end
