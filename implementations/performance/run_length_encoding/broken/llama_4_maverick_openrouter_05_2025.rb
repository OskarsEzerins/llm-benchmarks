module RLE
  def self.rle_encode(input_str)
    return "" if input_str.empty?

    encoded_str = ""
    count = 1
    prev_char = input_str[0]

    (1...input_str.length).each do |i|
      if input_str[i] == prev_char
        count += 1
      else
        encoded_str += prev_char + count.to_s
        prev_char = input_str[i]
        count = 1
      end
    end

    encoded_str += prev_char + count.to_s
    encoded_str
  end

  def self.rle_decode(encoded_str)
    return "" if encoded_str.empty? || encoded_str.length % 2 != 0

    decoded_str = ""
    (0...encoded_str.length).step(2) do |i|
      char = encoded_str[i]
      count = encoded_str[i + 1].to_i
      decoded_str += char * count
    end

    decoded_str
  end
end