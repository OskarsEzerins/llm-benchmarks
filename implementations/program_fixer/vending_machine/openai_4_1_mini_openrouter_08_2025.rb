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
        price = price.is_a?(Numeric) ? price.to_f : 1.25
        quantity = quantity.is_a?(Integer) && quantity >= 0 ? quantity : 0
        @items << { name: name.to_s, price: price, quantity: quantity }
      end
    end
    @balance = 0.0
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric)
    return if amount <= 0

    @balance += amount.to_f
  end

  def select_item(name)
    return "Item not found" if name.nil? || name.to_s.strip.empty?

    item = @items.find { |i| i[:name] == name.to_s }
    return "Item not found" if item.nil?

    if item[:quantity] == 0
      return "Item out of stock"
    elsif @balance < item[:price]
      return "Insufficient funds. Please insert more money."
    end

    @balance -= item[:price]
    item[:quantity] -= 1
    "Dispensed #{name}"
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def check_stock(name)
    return 0 if name.nil? || name.to_s.strip.empty?

    item = @items.find { |i| i[:name] == name.to_s }
    item ? item[:quantity].to_i : 0
  end

  def restock(name, quantity)
    return if name.nil? || name.to_s.strip.empty?
    return unless quantity.is_a?(Integer) && quantity > 0

    item = @items.find { |i| i[:name] == name.to_s }
    if item
      item[:quantity] += quantity
    else
      @items << { name: name.to_s, price: 1.25, quantity: quantity }
    end
  end

  def get_available_items
    @items.select { |item| item[:quantity] > 0 }
  end
end