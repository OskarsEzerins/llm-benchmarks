class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = []
    @balance = 0.0

    Array(items).each do |item|
      next unless item.is_a?(Hash)

      name = item[:name]
      price = numeric_float(item[:price])
      quantity = integer_quantity(item[:quantity])

      next unless valid_name?(name)
      next unless price && price >= 0.0
      next unless quantity && quantity >= 0

      @inventory << {
        name: name,
        price: price,
        quantity: quantity
      }
    end
  end

  def insert_money(amount)
    value = numeric_float(amount)
    return @balance unless value && value.positive?

    @balance += value
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
    return nil unless valid_name?(name)

    amount = integer_quantity(quantity)
    return nil unless amount && amount.positive?

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

    amount
  end

  def get_available_items
    @inventory.select { |item| item[:quantity] > 0 }
  end

  private

  def valid_name?(name)
    name.is_a?(String) && !name.empty?
  end

  def numeric_float(value)
    return nil unless value.is_a?(Numeric)

    number = Float(value)
    number.finite? ? number : nil
  rescue ArgumentError, TypeError, RangeError
    nil
  end

  def integer_quantity(value)
    return value if value.is_a?(Integer)
    return nil unless value.is_a?(Numeric)

    number = numeric_float(value)
    return nil unless number && number == number.to_i

    number.to_i
  end
end