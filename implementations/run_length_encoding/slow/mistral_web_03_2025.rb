module RLE
  def self.rle_encode(input)
    return '' if input.empty?

    encoded = ''
    count = 1
    input.chars.each_with_index do |char, index|
      if char == input[index + 1]
        count += 1
      else
        encoded += "#{char}#{count}"
        count = 1
      end
    end
    encoded
  end

  def self.rle_decode(encoded)
    return '' if encoded.empty?

    decoded = ''
    encoded.scan(/([A-Z])(\d+)/) do |char, count|
      decoded += char * count.to_i
    end
    decoded
  end
end
