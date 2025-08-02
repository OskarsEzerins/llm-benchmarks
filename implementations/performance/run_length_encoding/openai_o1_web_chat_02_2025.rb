module RLE
  def self.rle_encode(s)
    return "" if s.empty?
    r, c, p = "", 1, s[0]
    (1...s.size).each do |i|
      if s[i] == p
        c += 1
      else
        r << "#{p}#{c}"
        p = s[i]
        c = 1
      end
    end
    r << "#{p}#{c}"
  end

  def self.rle_decode(s)
    return "" if s.empty?
    r, i = "", 0
    while i < s.size
      ch = s[i]; i += 1
      n = 0
      while i < s.size && s[i] =~ /\d/
        n = n * 10 + s[i].to_i
        i += 1
      end
      r << ch * n
    end
    r
  end
end
