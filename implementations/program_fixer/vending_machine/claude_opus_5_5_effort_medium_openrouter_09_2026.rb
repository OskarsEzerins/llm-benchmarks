class VendingMachine
  DEFAULT_RESTOCK_PRICE = 1.25

  attr_reader :balance

  def initialize(items = nil)
    @inventory = []
    @balance   = 0.0

    return unless items.is_a?(Array)

    items.each do |raw|
      item = normalize_item(raw)
      @inventory << item if item
    end
  end

  def inventory
    @inventory
  end

  def insert_money(amount)
    return @balance unless valid_amount?(amount)

    @balance = (@balance + amount.to_f).round(2)
    @balance
  end

  def select_item(label)
    return 'Item not found' unless valid_label?(label)

    item = find_item(label)

    return 'Item not found' if item.nil?
    return 'Item out of stock' if item[:quantity] <= 0
    return 'Insufficient funds. Please insert more money.' if @balance < item[:price]

    @balance = (@balance - item[:price]).round(2)
    @balance = 0.0 if @balance.abs < 1e-9
    item[:quantity] -= 1
    "Dispensed #{item[:name]}"
  end

  def return_change
    change = @balance.to_f
    @balance = 0.0
    change
  end

  def check_stock(label)
    return 0 unless valid_label?(label)

    item = find_item(label)
    item ? item[:quantity].to_i : 0
  end

  def restock(label, qty)
    return false unless valid_label?(label)
    return false unless qty.is_a?(Integer) && qty > 0

    item = find_item(label)
    if item
      item[:quantity] += qty
    else
      @inventory << { name: label.to_s, price: DEFAULT_RESTOCK_PRICE, quantity: qty }
    end
    true
  end

  def get_available_items
    @inventory.select { |i| i[:quantity] > 0 }
  end

  private

  def find_item(label)
    @inventory.find { |i| i[:name] == label.to_s }
  end

  def valid_label?(label)
    return false if label.nil?
    return false unless label.is_a?(String) || label.is_a?(Symbol)

    !label.to_s.strip.empty?
  end

  def valid_amount?(amount)
    return false unless amount.is_a?(Numeric)
    return false if amount.is_a?(Complex)

    value = amount.to_f
    return false if value.nan? || value.infinite?

    value > 0
  end

  def normalize_item(raw)
    return nil unless raw.is_a?(Hash)

    name     = raw[:name]     || raw['name']
    price    = raw[:price]    || raw['price']
    quantity = raw[:quantity] || raw['quantity'] || 0

    return nil if name.nil? || name.to_s.strip.empty?
    return nil unless price.is_a?(Numeric) && !price.is_a?(Complex) && price >= 0
    return nil unless quantity.is_a?(Numeric) && !quantity.is_a?(Complex)

    quantity = quantity.to_i
    quantity = 0 if quantity < 0

    { name: name.to_s, price: price.to_f, quantity: quantity }
  end
end