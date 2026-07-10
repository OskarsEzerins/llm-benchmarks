class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = []

    if items.is_a?(Array)
      items.each do |item|
        normalized_item = normalize_item(item)
        @inventory << normalized_item if normalized_item
      end
    end

    @balance = 0.0
  end

  def insert_money(amount)
    value = numeric_value(amount)
    return unless value && value.positive?

    @balance += value
  end

  def select_item(name)
    return "Item not found" unless valid_name?(name)

    item = @inventory.find { |inventory_item| inventory_item[:name] == name }

    return "Item not found" unless item
    return "Item out of stock" if item[:quantity].zero?
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

    item = @inventory.find { |inventory_item| inventory_item[:name] == name }
    item ? item[:quantity] : 0
  end

  def restock(name, quantity)
    return unless valid_name?(name)

    amount = integer_value(quantity)
    return unless amount && amount.positive?

    item = @inventory.find { |inventory_item| inventory_item[:name] == name }

    if item
      item[:quantity] += amount
    else
      @inventory << { name: name, price: 1.25, quantity: amount }
    end
  end

  def get_available_items
    @inventory.select { |item| item[:quantity].positive? }
  end

  private

  def normalize_item(item)
    return unless item.is_a?(Hash)

    name = item[:name]
    price = numeric_value(item[:price])
    quantity = integer_value(item[:quantity])

    return unless valid_name?(name)
    return unless price && price >= 0.0
    return unless quantity && quantity >= 0

    { name: name, price: price, quantity: quantity }
  end

  def valid_name?(name)
    name.is_a?(String) && !name.empty?
  end

  def numeric_value(value)
    return unless value.is_a?(Numeric)

    number = Float(value)
    number if number.finite?
  rescue ArgumentError, TypeError, RangeError
    nil
  end

  def integer_value(value)
    number = numeric_value(value)
    return unless number && number == number.to_i

    number.to_i
  end
end