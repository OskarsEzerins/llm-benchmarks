require 'strscan'

module RLE
  module_function

  def rle_encode(str)
    return "" if str.empty?
    result = +""
    prev = nil
    count = 0
    str.each_char do |ch|
      if ch == prev
        count += 1
      else
        if prev
          result << prev << count.to_s
        end
        prev = ch
        count = 1
      end
    end
    result << prev << count.to_s
    result
  end

  def rle_decode(str)
    return "" if str.empty?
    result = +""
    scanner = StringScanner.new(str)
    until scanner.eos?
      char = scanner.getch
      count_token = scanner.scan(/\d+/)
      count = count_token ? count_token.to_i : 1
      result << char * count
    end
    result
  end
end