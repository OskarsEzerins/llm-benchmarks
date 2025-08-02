# frozen_string_literal: true

class VendingMachine
  attr_reader :items, :balance

  def initialize(items)
    @items = []
    if items.is_a?(Array)
      items.each do |item|
        if item.is_a?(Hash) && item[:name] && item[:price] && item[:quantity]
          @items << {
            name: item[:name],
            price: item[:price].to_f,
            quantity: item[:quantity].to_i
          }
        end
      end
    end
    @balance = 0.0
  end

  def insert_money(amount)
    if amount.is_a?(Numeric) && amount > 0
      @balance += amount.to_f
    end
  end

  def select_item(name)
    return "Item not found" if name.nil? || name.strip.empty?

    item = @items.find { |i| i[:name] == name }
    return "Item not found" if item.nil?

    if item[:quantity] == 0
      return "Item out of stock"
    elsif @balance < item[:price]
      return "Insufficient funds. Please insert more money."
    else
      @balance -= item[:price]
      item[:quantity] -= 1
      return "Dispensed #{name}"
    end
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def check_stock(name)
    return 0 if name.nil?
    item = @items.find { |i| i[:name] == name }
    item ? item[:quantity] : 0
  end

  def restock(name, quantity)
    return unless name.is_a?(String) && quantity.is_a?(Numeric) && quantity > 0
    item = @items.find { |i| i[:name] == name }
    if item
      item[:quantity] += quantity.to_i
    else
      @items << { name: name, price: 1.25, quantity: quantity.to_i }
    end
  end

  def get_available_items
    @items.select { |item| item[:quantity] > 0 }
  end
end