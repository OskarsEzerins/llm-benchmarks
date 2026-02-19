module RLE
  def self.rle_encode(str)
    str.gsub(/(.)\1*/) { "#{$1}#{$&.length}" }
  end

  def self.rle_decode(str)
    str.gsub(/(.)(\d+)/) { $1 * $2.to_i }
  end
end