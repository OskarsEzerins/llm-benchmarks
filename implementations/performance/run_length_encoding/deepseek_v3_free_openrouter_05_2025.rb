module RLE
  def self.rle_encode(input)
    return "" if input.empty?

    encoded = []
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
    encoded.join
  end

  def self.rle_decode(input)
    return "" if input.empty?

    decoded = []
    i = 0
    while i < input.length
      char = input[i]
      i += 1
      count = ""
      while i < input.length && input[i] =~ /\d/
        count += input[i]
        i += 1
      end
      count = count.empty? ? 1 : count.to_i
      decoded << char * count
    end
    decoded.join
  end
end