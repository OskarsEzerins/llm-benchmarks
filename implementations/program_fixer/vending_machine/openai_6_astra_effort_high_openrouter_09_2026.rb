class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = []
    @balance = 0.0

    return unless items.is_a?(Array)

    items.each do |item|
      next unless item.is_a?(Hash)
      next unless valid_name?(item[:name])

      price = numeric_float(item[:price])
      quantity = item[:quantity]

      next unless price && price >= 0.0
      next unless quantity.is_a?(Integer) && quantity >= 0

      @inventory << {
        name: item[:name],
        price: price,
        quantity: quantity
      }
    end
  end

  def insert_money(amount)
    amount = numeric_float(amount)
    return unless amount && amount > 0.0

    @balance += amount
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

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def check_stock(name)
    return 0 unless valid_name?(name)

    item = @inventory.find { |entry| entry[:name] == name }
    item ? item[:quantity] : 0
  end

  def restock(name, quantity)
    return unless valid_name?(name)
    return unless quantity.is_a?(Integer) && quantity > 0

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

  def valid_name?(name)
    name.is_a?(String) && !name.empty?
  end

  def numeric_float(value)
    return nil unless value.is_a?(Numeric) && value.real?

    number = Float(value)
    number.finite? ? number : nil
  rescue ArgumentError, TypeError, RangeError
    nil
  end
end