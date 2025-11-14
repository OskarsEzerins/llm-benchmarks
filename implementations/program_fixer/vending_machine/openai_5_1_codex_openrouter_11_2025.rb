class VendingMachine
  DEFAULT_RESTOCK_PRICE = 1.25

  attr_reader :balance

  def initialize(items = [])
    @inventory = []
    Array(items).each do |item|
      next unless item.is_a?(Hash)
      name = normalize_name(item[:name])
      next unless name
      price = item[:price]
      next unless numeric?(price)

      quantity = item[:quantity]
      quantity = numeric?(quantity) ? quantity.to_i : 0
      quantity = 0 if quantity.negative?

      @inventory << { name: name, price: price.to_f, quantity: quantity }
    end
    @balance = 0.0
  end

  def insert_money(amount)
    return @balance unless valid_amount?(amount)

    @balance += amount.to_f
    @balance
  end

  def select_item(name)
    normalized = normalize_name(name)
    return "Item not found" unless normalized

    item = find_item_by_name(normalized)
    return "Item not found" unless item
    return "Item out of stock" if item[:quantity] <= 0
    if @balance < item[:price]
      return "Insufficient funds. Please insert more money."
    end

    item[:quantity] -= 1
    @balance -= item[:price]
    "Dispensed #{item[:name]}"
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def check_stock(name)
    normalized = normalize_name(name)
    return 0 unless normalized

    item = find_item_by_name(normalized)
    item ? item[:quantity] : 0
  end

  def restock(name, quantity)
    normalized = normalize_name(name)
    return nil unless normalized && numeric?(quantity) && quantity.to_i > 0

    qty = quantity.to_i
    item = find_item_by_name(normalized)
    if item
      item[:quantity] += qty
    else
      @inventory << { name: normalized, price: DEFAULT_RESTOCK_PRICE, quantity: qty }
      item = @inventory.last
    end
    item[:quantity]
  end

  def get_available_items
    @inventory.select { |item| item[:quantity] > 0 }.map(&:dup)
  end

  private

  def find_item_by_name(name)
    @inventory.find { |item| item[:name] == name }
  end

  def numeric?(value)
    value.is_a?(Numeric)
  end

  def valid_amount?(amount)
    numeric?(amount) && amount > 0
  end

  def normalize_name(name)
    return nil unless name.respond_to?(:to_s)

    trimmed = name.to_s.strip
    trimmed.empty? ? nil : trimmed
  end
end