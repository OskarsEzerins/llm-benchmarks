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

      next unless valid_name?(name)
      next unless numeric_value?(price)
      next unless quantity.is_a?(Numeric) && quantity.to_i >= 0

      @inventory << {
        name: name,
        price: price.to_f,
        quantity: quantity.to_i
      }
    end
  end

  def insert_money(amount)
    return unless numeric_value?(amount) && amount.to_f > 0

    @balance += amount.to_f
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def select_item(name)
    return "Item not found" unless valid_name?(name)

    item = @inventory.find { |entry| entry[:name] == name }
    return "Item not found" unless item
    return "Item out of stock" if item[:quantity] <= 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price]

    @balance -= item[:price]
    item[:quantity] -= 1
    "Dispensed #{name}"
  end

  def check_stock(name)
    return 0 unless valid_name?(name)

    item = @inventory.find { |entry| entry[:name] == name }
    item ? item[:quantity].to_i : 0
  end

  def restock(name, quantity)
    return unless valid_name?(name)
    return unless quantity.is_a?(Numeric) && quantity.to_i > 0

    amount = quantity.to_i
    item = @inventory.find { |entry| entry[:name] == name }

    if item
      item[:quantity] += amount
    else
      @inventory << {
        name: name,
        price: 1.25,
        quantity: amount
      }
    end
  end

  def get_available_items
    @inventory.select { |item| item[:quantity] > 0 }
  end

  private

  def valid_name?(name)
    name.is_a?(String) && !name.empty?
  end

  def numeric_value?(value)
    return false unless value.is_a?(Numeric)

    converted = value.to_f
    converted.finite?
  end
end