module RLE
  module_function

  def rle_encode(str)
    return "" if str.empty?

    arr = []
    prev = str[0]
    count = 1
    i = 1
    len = str.length

    while i < len
      ch = str[i]
      if ch == prev
        count += 1
      else
        arr << prev
        arr << count.to_s
        prev = ch
        count = 1
      end
      i += 1
    end

    arr << prev
    arr << count.to_s
    arr.join
  end

  def rle_decode(encoded)
    return "" if encoded.empty?

    arr = []
    encoded.scan(/([^0-9])(\d*)/) do |char, cnt|
      c = cnt.empty? ? 1 : cnt.to_i
      arr << char * c
    end
    arr.join
  end
end