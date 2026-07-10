class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = []
    @balance = 0.0

    return unless items.is_a?(Array)

    items.each do |item|
      next unless item.is_a?(Hash)

      name = item[:name]
      price = normalize_price(item[:price])
      quantity = normalize_quantity(item[:quantity], allow_zero: true)

      next unless valid_name?(name)
      next if price.nil? || quantity.nil?

      @inventory << {
        name: name,
        price: price,
        quantity: quantity
      }
    end
  end

  def insert_money(amount)
    value = normalize_positive_number(amount)
    return @balance if value.nil?

    @balance += value
  end

  def select_item(name)
    return "Item not found" unless valid_name?(name)

    item = @inventory.find { |entry| entry[:name] == name }

    return "Item not found" if item.nil?
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

    amount = normalize_quantity(quantity, allow_zero: false)
    return if amount.nil?

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

  def normalize_positive_number(value)
    return nil unless value.is_a?(Numeric)

    number = Float(value)
    return nil unless number.finite? && number.positive?

    number
  rescue ArgumentError, TypeError, RangeError
    nil
  end

  def normalize_price(value)
    return nil unless value.is_a?(Numeric)

    price = Float(value)
    return nil unless price.finite? && price >= 0.0

    price
  rescue ArgumentError, TypeError, RangeError
    nil
  end

  def normalize_quantity(value, allow_zero:)
    return nil unless value.is_a?(Numeric)

    number = Float(value)
    return nil unless number.finite? && number == number.to_i

    quantity = number.to_i
    return nil if allow_zero ? quantity.negative? : !quantity.positive?

    quantity
  rescue ArgumentError, TypeError, RangeError
    nil
  end
end