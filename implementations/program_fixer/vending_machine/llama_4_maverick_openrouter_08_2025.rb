# frozen_string_literal: true

class VendingMachine
  attr_reader :items, :balance

  def initialize(items)
    @items = items || []
    @balance = 0.0
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric) && amount > 0

    @balance += amount.to_f
  end

  def select_item(name)
    return "Item not found" if name.nil? || name.empty?

    item = @items.find { |i| i[:name] == name }

    if item.nil?
      "Item not found"
    elsif item[:quantity] == 0
      "Item out of stock"
    elsif @balance < item[:price]
      "Insufficient funds. Please insert more money."
    else
      @balance -= item[:price]
      item[:quantity] -= 1
      "Dispensed #{name}"
    end
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def check_stock(name)
    return 0 if name.nil? || name.empty?

    item = @items.find { |i| i[:name] == name }
    item ? item[:quantity] : 0
  end

  def restock(name, quantity)
    return if quantity.nil? || !quantity.is_a?(Integer) || quantity < 0

    item = @items.find { |i| i[:name] == name }
    if item
      item[:quantity] += quantity
    else
      @items << { name: name, price: 1.25, quantity: quantity }
    end
  end

  def get_available_items
    @items.select { |item| item[:quantity] > 0 }
  end
end