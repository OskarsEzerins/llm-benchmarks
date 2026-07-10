class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = []
    @balance = 0.0

    Array(items).each do |item|
      next unless item.is_a?(Hash)

      name = item[:name]
      price = item[:price]
      quantity = item[:quantity]

      next if invalid_name?(name)
      next unless numeric_value?(price)
      next unless quantity.is_a?(Integer) && quantity >= 0

      @inventory << {
        name: name,
        price: price.to_f,
        quantity: quantity
      }
    end
  end

  def insert_money(amount)
    return unless numeric_value?(amount)
    return unless amount > 0

    @balance += amount.to_f
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def select_item(name)
    return "Item not found" if invalid_name?(name)

    item = @inventory.find { |entry| entry[:name] == name }
    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity] == 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price]

    @balance -= item[:price]
    item[:quantity] -= 1

    "Dispensed #{name}"
  end

  def check_stock(name)
    return 0 if invalid_name?(name)

    item = @inventory.find { |entry| entry[:name] == name }
    item ? item[:quantity].to_i : 0
  end

  def restock(name, quantity)
    return unless valid_restock_quantity?(quantity)
    return if invalid_name?(name)

    item = @inventory.find { |entry| entry[:name] == name }

    if item
      item[:quantity] += quantity
    else
      @inventory << {
        name: name,
        price: 1.25,
        quantity: quantity
      }
    end
  end

  def get_available_items
    @inventory.select { |item| item[:quantity] > 0 }
  end

  private

  def invalid_name?(name)
    name.nil? || (name.respond_to?(:empty?) && name.empty?)
  end

  def numeric_value?(value)
    return false unless value.is_a?(Numeric)
    return false if value.respond_to?(:finite?) && !value.finite?

    value > 0
  rescue TypeError, ArgumentError
    false
  end

  def valid_restock_quantity?(quantity)
    quantity.is_a?(Integer) && quantity > 0
  end
end