class VendingMachine
  attr_reader :balance

  def initialize(items = [])
    @inventory = []
    @balance = 0.0
    Array(items).each do |item|
      next unless item.is_a?(Hash)
      name = item[:name]
      price = item[:price]
      quantity = item[:quantity]

      next if name.nil? || (name.respond_to?(:strip) && name.strip.empty?)
      next unless price.is_a?(Numeric)

      quantity = quantity.is_a?(Numeric) ? quantity.to_i : 0
      quantity = 0 if quantity.negative?

      @inventory << {
        name: name,
        price: price.to_f,
        quantity: quantity
      }
    end
  end

  def insert_money(amount)
    return @balance unless amount.is_a?(Numeric)
    return @balance unless amount.positive?

    @balance += amount.to_f
    @balance
  end

  def select_item(name)
    return "Item not found" if name.nil? || (name.respond_to?(:strip) && name.strip.empty?)

    item = @inventory.find { |i| i[:name] == name }
    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity].to_i <= 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price]

    @balance -= item[:price]
    item[:quantity] -= 1
    "Dispensed #{item[:name]}"
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def check_stock(name)
    return 0 if name.nil? || (name.respond_to?(:strip) && name.strip.empty?)

    item = @inventory.find { |i| i[:name] == name }
    item ? item[:quantity].to_i : 0
  end

  def restock(name, quantity)
    return nil if name.nil? || (name.respond_to?(:strip) && name.strip.empty?)
    return nil unless quantity.is_a?(Numeric)
    quantity = quantity.to_i
    return nil if quantity <= 0

    item = @inventory.find { |i| i[:name] == name }
    if item
      item[:quantity] += quantity
      item[:quantity]
    else
      @inventory << { name: name, price: 1.25, quantity: quantity }
      quantity
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity].to_i > 0 }
  end
end