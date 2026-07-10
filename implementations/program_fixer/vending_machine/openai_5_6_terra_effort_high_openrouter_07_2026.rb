class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = []
    @balance = 0.0

    return unless items.is_a?(Array)

    items.each do |item|
      normalized_item = normalize_item(item)
      @inventory << normalized_item if normalized_item
    end
  end

  def insert_money(amount)
    value = floating_number(amount)
    return nil if value.nil? || value <= 0

    new_balance = @balance + value
    return nil unless new_balance.finite?

    @balance = new_balance
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def select_item(name)
    return "Item not found" unless valid_name?(name)

    item = @inventory.find { |inventory_item| inventory_item[:name] == name }
    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity] <= 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price]

    @balance -= item[:price]
    item[:quantity] -= 1

    "Dispensed #{name}"
  end

  def check_stock(name)
    return 0 unless valid_name?(name)

    item = @inventory.find { |inventory_item| inventory_item[:name] == name }
    item ? item[:quantity] : 0
  end

  def restock(name, quantity)
    return nil unless valid_name?(name)

    quantity = valid_quantity(quantity)
    return nil if quantity.nil? || quantity <= 0

    item = @inventory.find { |inventory_item| inventory_item[:name] == name }

    if item
      item[:quantity] += quantity
    else
      @inventory << { name: name, price: 1.25, quantity: quantity }
    end
  end

  def get_available_items
    @inventory.select { |item| item[:quantity] > 0 }
  end

  private

  def normalize_item(item)
    return nil unless item.is_a?(Hash)
    return nil unless valid_name?(item[:name])

    price = floating_number(item[:price])
    quantity = valid_quantity(item[:quantity])

    return nil if price.nil? || price < 0 || quantity.nil?

    {
      name: item[:name],
      price: price,
      quantity: quantity
    }
  end

  def valid_name?(name)
    name.is_a?(String) && !name.empty?
  end

  def valid_quantity(quantity)
    value = floating_number(quantity)
    return nil if value.nil? || value < 0 || value != value.to_i

    value.to_i
  end

  def floating_number(value)
    return nil unless value.is_a?(Numeric)

    number = value.to_f
    number.finite? ? number : nil
  rescue StandardError
    nil
  end
end