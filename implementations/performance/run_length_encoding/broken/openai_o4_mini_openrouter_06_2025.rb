module RLE
  def self.rle_encode(s)
    return '' if s.empty?
    res = ''
    prev = s[0]
    count = 1
    s.each_char.with_index(1) do |ch, i|
      if ch == prev
        count += 1
      else
        res << prev << count.to_s
        prev = ch
        count = 1
      end
    end
    res << prev << count.to_s
    res
  end

  def self.rle_decode(s)
    return '' if s.empty?
    res = ''
    i = 0
    len = s.length
    while i < len
      ch = s[i]
      i += 1
      start = i
      while i < len && s[i] >= '0' && s[i] <= '9'
        i += 1
      end
      count = s[start...i].to_i
      res << ch * count
    end
    res
  end
end