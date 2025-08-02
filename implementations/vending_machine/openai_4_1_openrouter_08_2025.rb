# frozen_string_literal: true

class VendingMachine
  attr_reader :items, :balance

  def initialize(items)
    @items = []
    if items.is_a?(Array)
      items.each do |item|
        next unless item.is_a?(Hash)
        name = item[:name]
        price = item[:price]
        quantity = item[:quantity]
        next if name.nil? || name.to_s.strip.empty?
        price = price.is_a?(Numeric) ? price.to_f : 0.0
        quantity = quantity.is_a?(Integer) ? quantity : 0
        @items << { name: name, price: price, quantity: quantity }
      end
    end
    @balance = 0.0
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric)
    return if amount.nil? || amount <= 0
    @balance = (@balance + amount.to_f).to_f
  end

  def select_item(name)
    return "Item not found" if name.nil? || name.to_s.strip.empty?
    item = @items.find { |i| i[:name] == name }
    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity] == 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price]
    @balance = (@balance - item[:price]).to_f
    item[:quantity] -= 1
    "Dispensed #{name}"
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def check_stock(name)
    return 0 if name.nil?
    item = @items.find { |i| i[:name] == name }
    item ? item[:quantity].to_i : 0
  end

  def restock(name, quantity)
    return if name.nil? || name.to_s.strip.empty?
    return unless quantity.is_a?(Integer) && quantity > 0
    item = @items.find { |i| i[:name] == name }
    if item
      item[:quantity] += quantity
    else
      @items << { name: name, price: 1.25, quantity: quantity }
    end
  end

  def get_available_items
    @items.select { |item| item[:quantity].to_i > 0 }
  end
end