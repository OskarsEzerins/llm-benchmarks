# frozen_string_literal: true

class VendingMachine
  attr_reader :items, :balance

  def initialize(items_data)
    @items = []
    items_data.each do |item_hash|
      if item_hash.is_a?(Hash) && item_hash[:name].is_a?(String) &&
         item_hash[:price].is_a?(Numeric) && item_hash[:quantity].is_a?(Integer) &&
         item_hash[:price] >= 0 && item_hash[:quantity] >= 0
        @items << {
          name: item_hash[:name],
          price: item_hash[:price].to_f,
          quantity: item_hash[:quantity].to_i
        }
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
    return "Item not found" if name.nil? || name.empty?

    item = @items.find { |i| i[:name] == name }

    if item.nil?
      return "Item not found"
    elsif item[:quantity] == 0
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
    return 0 if name.nil? || name.empty?

    item = @items.find { |i| i[:name] == name }
    item ? item[:quantity] : 0
  end

  def restock(name, quantity)
    return unless name.is_a?(String) && !name.empty?
    return unless quantity.is_a?(Integer) && quantity > 0

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