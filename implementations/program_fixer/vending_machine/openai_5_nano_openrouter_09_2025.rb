class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = []
    if items.is_a?(Array)
      items.each do |item|
        next unless item.is_a?(Hash)
        name = item[:name]
        price = item[:price]
        quantity = item[:quantity]
        if name.is_a?(String) && price.is_a?(Numeric) && quantity.is_a?(Integer)
          @inventory << { name: name, price: price.to_f, quantity: quantity.to_i }
        end
      end
    end
    @balance = 0.0
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric) && amount > 0
    @balance = @balance.to_f + amount.to_f
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def select_item(name)
    if name.nil? || !name.is_a?(String) || name.strip.empty?
      return "Item not found"
    end

    item = @inventory.find { |i| i[:name] == name }

    unless item
      return "Item not found"
    end

    if item[:quantity] <= 0
      return "Item out of stock"
    end

    price = item[:price] || 0.0
    if @balance < price
      return "Insufficient funds. Please insert more money."
    end

    @balance -= price
    item[:quantity] -= 1
    "Dispensed #{name}"
  end

  def check_stock(name)
    return 0 if name.nil? || !name.is_a?(String) || name.strip.empty?
    item = @inventory.find { |i| i[:name] == name }
    item ? item[:quantity] : 0
  end

  def restock(name, qty)
    return unless name.is_a?(String) && !name.strip.empty?
    return unless qty.is_a?(Integer) && qty > 0

    stock = @inventory.find { |i| i[:name] == name }
    if stock
      stock[:quantity] += qty
    else
      @inventory << { name: name, price: 1.25, quantity: qty }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity] > 0 }
  end
end