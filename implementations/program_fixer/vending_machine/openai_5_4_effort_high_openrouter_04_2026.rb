class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = []
    @balance = 0.0

    raw_items =
      if items.is_a?(Array)
        items
      elsif items.is_a?(Hash)
        [items]
      else
        []
      end

    raw_items.each do |item|
      next unless item.is_a?(Hash)

      name = item[:name]
      price = item[:price]
      quantity = item[:quantity]

      next if invalid_name?(name)
      next unless price.is_a?(Numeric)
      next unless quantity.is_a?(Numeric)

      normalized_price = price.to_f.round(2)
      normalized_quantity = quantity.to_i
      normalized_price = 0.0 if normalized_price.negative?
      normalized_quantity = 0 if normalized_quantity.negative?

      @inventory << {
        name: name,
        price: normalized_price,
        quantity: normalized_quantity
      }
    end
  end

  def insert_money(amount)
    return @balance unless amount.is_a?(Numeric) && amount.positive?

    @balance = (@balance + amount.to_f).round(2)
  end

  def return_change
    change = @balance.to_f
    @balance = 0.0
    change
  end

  def select_item(name)
    return "Item not found" if invalid_name?(name)

    item = @inventory.find { |i| i[:name] == name }
    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity].to_i <= 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price].to_f

    @balance = (@balance - item[:price].to_f).round(2)
    item[:quantity] = item[:quantity].to_i - 1

    "Dispensed #{name}"
  end

  def check_stock(name)
    return 0 if invalid_name?(name)

    item = @inventory.find { |i| i[:name] == name }
    item ? item[:quantity].to_i : 0
  end

  def restock(name, quantity)
    return nil if invalid_name?(name)
    return nil unless quantity.is_a?(Numeric)

    qty = quantity.to_i
    return nil if qty <= 0

    item = @inventory.find { |i| i[:name] == name }

    if item
      item[:quantity] = item[:quantity].to_i + qty
    else
      @inventory << {
        name: name,
        price: 1.25,
        quantity: qty
      }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity].to_i > 0 }
  end

  private

  def invalid_name?(name)
    return true if name.nil?
    return name.strip.empty? if name.is_a?(String)

    name.respond_to?(:empty?) ? name.empty? : false
  end
end