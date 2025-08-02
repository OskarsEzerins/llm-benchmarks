module RLE
  def self.rle_encode(input)
    return "" if input.empty?

    result = []
    count = 1
    prev_char = input[0]

    (1...input.length).each do |i|
      if input[i] == prev_char
        count += 1
      else
        result << "#{prev_char}#{count}"
        prev_char = input[i]
        count = 1
      end
    end

    result << "#{prev_char}#{count}"
    result.join
  end

  def self.rle_decode(input)
    return "" if input.empty?

    result = []
    char = nil
    count_str = []

    input.each_char do |c|
      if c.match?(/\d/)
        count_str << c
      else
        if char && !count_str.empty?
          result << char * count_str.join.to_i
          count_str.clear
        end
        char = c
      end
    end

    result << char * count_str.join.to_i if char && !count_str.empty?
    result.join
  end
end
