module RLE
  def self.rle_encode(str)
    return "" if str.empty?
    encoded = []
    current_char = str[0]
    count = 1
    len = str.length

    (1...len).each do |i|
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

  def self.rle_decode(str)
    return "" if str.empty?
    decoded = []
    i = 0
    len = str.length

    while i < len
      char = str[i]
      i += 1
      num_start = i
      while i < len && str[i] =~ /\d/
        i += 1
      end
      count = str[num_start...i].to_i
      decoded << char * count
    end
    decoded.join
  end
end