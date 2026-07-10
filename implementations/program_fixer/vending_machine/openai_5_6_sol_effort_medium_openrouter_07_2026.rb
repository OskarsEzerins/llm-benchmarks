class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = normalize_items(items)
    @balance = 0.0
  end

  def insert_money(amount)
    value = valid_number(amount)
    return unless value && value.positive?

    @balance += value
  end

  def select_item(name)
    return "Item not found" if invalid_name?(name)

    item = @inventory.find { |entry| entry[:name] == name }

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
    return 0 if invalid_name?(name)

    item = @inventory.find { |entry| entry[:name] == name }
    item ? item[:quantity] : 0
  end

  def restock(name, quantity)
    return if invalid_name?(name)

    amount = valid_quantity(quantity)
    return unless amount && amount.positive?

    item = @inventory.find { |entry| entry[:name] == name }

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

  def normalize_items(items)
    return [] unless items.is_a?(Array)

    items.filter_map do |item|
      next unless item.is_a?(Hash)

      name = item[:name]
      price = valid_number(item[:price])
      quantity = valid_quantity(item[:quantity])

      next if invalid_name?(name)
      next unless price && price >= 0.0
      next unless quantity && quantity >= 0

      item.merge(name: name, price: price, quantity: quantity)
    end
  end

  def valid_number(value)
    return unless value.is_a?(Numeric)

    number = Float(value)
    number if number.finite?
  rescue ArgumentError, TypeError, RangeError
    nil
  end

  def valid_quantity(value)
    number = valid_number(value)
    return unless number && number == number.to_i

    number.to_i
  end

  def invalid_name?(name)
    name.nil? || (name.respond_to?(:empty?) && name.empty?)
  end
end