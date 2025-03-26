# frozen_string_literal: true

require 'stringio'

# Module for Run-Length Encoding and Decoding
module RLE
  # Encodes a string using Run-Length Encoding.
  #
  # @param input_string [String] The string to encode.
  # @return [String] The RLE encoded string.
  def self.rle_encode(input_string)
    return '' if input_string.empty?

    encoded = StringIO.new
    input_string.chars.chunk { |char| char }.each do |char, chunk|
      encoded << char
      encoded << chunk.length.to_s
    end
    encoded.string
  end

  # Decodes a Run-Length Encoded string.
  #
  # @param encoded_string [String] The RLE encoded string.
  # @return [String] The decoded string.
  def self.rle_decode(encoded_string)
    return '' if encoded_string.empty?

    decoded = StringIO.new
    encoded_string.scan(/(\D|\d)(\d+)/) do |char, count|
      decoded << char * count.to_i
    end
    decoded.string
  end
end
