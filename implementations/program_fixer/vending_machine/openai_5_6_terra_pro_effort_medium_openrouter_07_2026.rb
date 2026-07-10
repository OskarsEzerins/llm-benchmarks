class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = []
    @balance = 0.0

    return unless items.is_a?(Array)

    items.each do |item|
      next unless item.is_a?(Hash)

      name = item[:name]
      price = valid_price(item[:price])
      quantity = valid_quantity(item[:quantity], minimum: 0)

      next if invalid_name?(name) || price.nil? || quantity.nil?

      @inventory << {
        name: name,
        price: price,
        quantity: quantity
      }
    end
  end

  def insert_money(amount)
    value = valid_money(amount)
    return if value.nil?

    @balance += value
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def select_item(name)
    return "Item not found" if invalid_name?(name)

    item = @inventory.find { |inventory_item| inventory_item[:name] == name }
    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity] <= 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price]

    @balance -= item[:price]
    item[:quantity] -= 1

    "Dispensed #{name}"
  end

  def check_stock(name)
    return 0 if invalid_name?(name)

    item = @inventory.find { |inventory_item| inventory_item[:name] == name }
    item ? item[:quantity] : 0
  end

  def restock(name, quantity)
    return if invalid_name?(name)

    quantity = valid_quantity(quantity, minimum: 1)
    return if quantity.nil?

    item = @inventory.find { |inventory_item| inventory_item[:name] == name }

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

  def valid_money(value)
    return nil unless value.is_a?(Numeric)

    number = Float(value)
    return nil unless number.finite? && number > 0

    number
  rescue ArgumentError, TypeError
    nil
  end

  def valid_price(value)
    return nil unless value.is_a?(Numeric)

    number = Float(value)
    return nil unless number.finite? && number >= 0

    number
  rescue ArgumentError, TypeError
    nil
  end

  def valid_quantity(value, minimum:)
    return nil unless value.is_a?(Numeric)

    number = Float(value)
    return nil unless number.finite?
    return nil unless number == number.to_i
    return nil if number < minimum

    number.to_i
  rescue ArgumentError, TypeError
    nil
  end
end