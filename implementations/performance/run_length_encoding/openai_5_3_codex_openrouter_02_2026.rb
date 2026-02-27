module RLE
  module_function

  def rle_encode(input)
    return "" if input.empty?

    output = String.new(capacity: input.length * 2)
    prev = nil
    count = 0

    input.each_char do |ch|
      if prev == ch
        count += 1
      else
        if prev
          output << prev
          output << count.to_s
        end
        prev = ch
        count = 1
      end
    end

    output << prev
    output << count.to_s
    output
  end

  def rle_decode(encoded)
    return "" if encoded.empty?

    output = String.new
    current = nil
    count = 0

    encoded.each_char do |ch|
      if ch >= "0" && ch <= "9"
        raise ArgumentError, "Malformed RLE input" if current.nil?
        count = (count * 10) + (ch.ord - 48)
      else
        if current
          raise ArgumentError, "Malformed RLE input" if count <= 0
          output << (current * count)
        end
        current = ch
        count = 0
      end
    end

    raise ArgumentError, "Malformed RLE input" if current.nil? || count <= 0
    output << (current * count)
    output
  end
end