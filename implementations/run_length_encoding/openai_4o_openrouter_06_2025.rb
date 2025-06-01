module RLE
  def self.rle_encode(input)
    return "" if input.empty?
    encoded = ""
    count = 1
    input.chars.each_cons(2) do |a, b|
      if a == b
        count += 1
      else
        encoded << a << count.to_s
        count = 1
      end
    end
    encoded << input[-1] << count.to_s
    encoded
  end

  def self.rle_decode(encoded)
    return "" if encoded.empty?
    decoded = ""
    matches = encoded.scan(/(\D)(\d+)/)
    matches.each do |char, num|
      decoded << char * num.to_i
    end
    decoded
  end
end