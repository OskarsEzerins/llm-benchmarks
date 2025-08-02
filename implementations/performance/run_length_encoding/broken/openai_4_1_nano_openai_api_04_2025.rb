module RLE
  def self.rle_encode(input)
    return "" if input.nil? || input.empty?

    encoded = ""
    count = 1
    prev_char = input[0]

    input.enum_cons(2) do |a, b|
      if a == b
        count += 1
      else
        encoded << prev_char << count.to_s
        prev_char = b
        count = 1
      end
    end

    # append last run
    encoded << prev_char << count.to_s
  end

  def self.rle_decode(encoded)
    return "" if encoded.nil? || encoded.empty?

    decoded = ""
    buffer = ""
    encoded.each_char do |char|
      if char =~ /\d/
        buffer << char
      else
        count = buffer.to_i
        decoded << char * count
        buffer = ""
      end
    end
    decoded
  end
end
