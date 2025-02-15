module RLE
  def self.rle_encode(str)
    return '' if str.empty?

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
    return '' if encoded_str.empty?

    decoded = []
    encoded_str.scan(/([^\d])(\d+)/) do |char, count|
      decoded << char * count.to_i
    end
    decoded.join
  end
end
