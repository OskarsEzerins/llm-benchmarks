module RLE
  def self.rle_encode(input)
    return "" if input.empty?

    encoded = ""
    count = 1
    (1...input.length).each do |i|
      if input[i] == input[i - 1]
        count += 1
      else
        encoded << "#{input[i - 1]}#{count}"
        count = 1
      end
    end
    encoded << "#{input[-1]}#{count}"
    encoded
  end

  def self.rle_decode(encoded)
    return "" if encoded.empty?

    decoded = ""
    i = 0
    while i < encoded.length
      char = encoded[i]
      i += 1
      count = ""
      while i < encoded.length && encoded[i].match?(/\d/)
        count << encoded[i]
        i += 1
      end
      decoded << char * count.to_i
    end
    decoded
  end
end