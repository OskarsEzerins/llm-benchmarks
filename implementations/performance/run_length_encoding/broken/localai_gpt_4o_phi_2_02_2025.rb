class RLE
  def self.rle_encode(input_str)
    if input_str.length <= 1
      return input_str
    end

    result = ""
    count = 1

    (1..input_str.length).each do |i|
      if input_str[i] == input_str[i - 1]
        count += 1
      else
        result += "#{input_str[i - 1]}#{count}"
        count = 1
      end
    end

    result += "#{input_str[input_str.length - 1]}#{count}"
    return result
  end

  def self.rle_decode(input_str)
    result = ""
    i = 0

    while i < input_str.length
      count = input_str[i + 1].to_i
      result += input_str[i] * count
      i += 2
    end

    return result
  end
end
