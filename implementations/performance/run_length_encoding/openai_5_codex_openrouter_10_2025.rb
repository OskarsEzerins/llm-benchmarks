module RLE
  module_function

  def rle_encode(str)
    return "" if str.empty?

    result = String.new(encoding: str.encoding)
    last_char = nil
    count = 0

    str.each_char do |ch|
      if ch == last_char
        count += 1
      else
        if last_char
          result << last_char
          result << count.to_s
        end
        last_char = ch
        count = 1
      end
    end

    result << last_char
    result << count.to_s
    result
  end

  def rle_decode(encoded)
    return "" if encoded.empty?

    result = String.new(encoding: encoded.encoding)
    last_char = nil
    count_buffer = String.new

    encoded.each_char do |ch|
      if ch >= "0" && ch <= "9"
        count_buffer << ch
      else
        if last_char
          count = count_buffer.empty? ? 1 : count_buffer.to_i
          result << last_char * count
          count_buffer.clear
        end
        last_char = ch
      end
    end

    if last_char
      count = count_buffer.empty? ? 1 : count_buffer.to_i
      result << last_char * count
    end

    result
  end
end