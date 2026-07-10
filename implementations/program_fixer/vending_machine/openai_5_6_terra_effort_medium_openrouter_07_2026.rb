class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = []

    if items.is_a?(Array)
      items.each do |item|
        next unless item.is_a?(Hash)
        next if invalid_name?(item[:name])

        @inventory << {
          name: item[:name],
          price: normalize_price(item[:price]),
          quantity: normalize_quantity(item[:quantity])
        }
      end
    end

    @balance = 0.0
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric)
    return unless amount > 0

    value = amount.to_f
    return unless value.finite?

    @balance += value
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def select_item(name)
    return "Item not found" if invalid_name?(name)

    item = @inventory.find { |i| i[:name] == name }
    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity] <= 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price]

    @balance -= item[:price]
    item[:quantity] -= 1

    "Dispensed #{name}"
  end

  def check_stock(name)
    return 0 if invalid_name?(name)

    item = @inventory.find { |i| i[:name] == name }
    item ? item[:quantity] : 0
  end

  def restock(name, quantity)
    return if invalid_name?(name)

    quantity = valid_restock_quantity(quantity)
    return if quantity.nil?

    item = @inventory.find { |i| i[:name] == name }

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

  def normalize_price(price)
    return 0.0 unless price.is_a?(Numeric)

    value = price.to_f
    value.finite? && value >= 0 ? value : 0.0
  end

  def normalize_quantity(quantity)
    return 0 unless quantity.is_a?(Numeric)

    value = Integer(quantity)
    value >= 0 ? value : 0
  rescue ArgumentError, TypeError
    0
  end

  def valid_restock_quantity(quantity)
    return nil unless quantity.is_a?(Numeric)

    value = Integer(quantity)
    return nil unless quantity == value && value > 0

    value
  rescue ArgumentError, TypeError
    nil
  end
end