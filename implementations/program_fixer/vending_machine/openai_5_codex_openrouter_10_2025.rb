class VendingMachine
  attr_reader :balance

  DEFAULT_PRICE = 1.25

  def initialize(items = nil)
    @inventory = []
    Array(items).each do |item|
      next unless item.is_a?(Hash)
      name = extract_name(item[:name])
      next if name.nil?
      price = extract_price(item[:price])
      quantity = extract_quantity(item[:quantity])
      @inventory << { name: name, price: price, quantity: quantity }
    end
    @balance = 0.0
  end

  def insert_money(amount)
    return @balance unless amount.is_a?(Numeric) && amount.positive?
    @balance += amount.to_f
  end

  def select_item(name)
    normalized_name = extract_name(name)
    return "Item not found" if normalized_name.nil?

    item = @inventory.find { |i| i[:name] == normalized_name }
    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity] <= 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price]

    @balance -= item[:price]
    item[:quantity] -= 1
    "Dispensed #{item[:name]}"
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def check_stock(name)
    normalized_name = extract_name(name)
    return 0 if normalized_name.nil?

    item = @inventory.find { |i| i[:name] == normalized_name }
    item ? item[:quantity] : 0
  end

  def restock(name, quantity)
    normalized_name = extract_name(name)
    quantity_value = extract_quantity(quantity, allow_zero: false)
    return 0 if normalized_name.nil? || quantity_value.nil?

    item = @inventory.find { |i| i[:name] == normalized_name }
    if item
      item[:quantity] += quantity_value
      item[:quantity]
    else
      @inventory << { name: normalized_name, price: DEFAULT_PRICE.to_f, quantity: quantity_value }
      quantity_value
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity] > 0 }.map(&:dup)
  end

  private

  def extract_name(name)
    return nil if name.nil?
    normalized = name.to_s.strip
    normalized.empty? ? nil : normalized
  end

  def extract_price(price)
    return 0.0 unless price.is_a?(Numeric)
    price.to_f
  end

  def extract_quantity(quantity, allow_zero: true)
    return nil unless quantity.is_a?(Numeric)
    quantity_value = quantity.to_i
    return nil if !allow_zero && quantity_value <= 0
    quantity_value.negative? ? 0 : quantity_value
  end
end