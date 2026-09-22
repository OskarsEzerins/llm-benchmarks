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
    return 'Item not found' unless valid_name?(label)

    item = find_item(label)

    return 'Item not found' if item.nil?
    return 'Item out of stock' if item[:quantity] <= 0
    return 'Insufficient funds. Please insert more money.' if @balance < item[:price]

    @balance = (@balance - item[:price]).round(2)
    item[:quantity] -= 1
    "Dispensed #{label}"
  end

  def return_change
    change = @balance.to_f
    @balance = 0.0
    change
  end

  def check_stock(label)
    return 0 unless valid_name?(label)

    item = find_item(label)
    item ? item[:quantity].to_i : 0
  end

  def restock(label, qty)
    return nil unless valid_name?(label)
    return nil unless qty.is_a?(Integer) && qty > 0

    item = find_item(label)
    if item
      item[:quantity] += qty
    else
      item = { name: label, price: DEFAULT_RESTOCK_PRICE, quantity: qty }
      @inventory << item
    end
    item
  end

  def get_available_items
    @inventory.select { |i| i[:quantity] > 0 }
  end

  private

  def find_item(label)
    @inventory.find { |i| i[:name] == label }
  end

  def valid_name?(label)
    !label.nil? && !label.to_s.strip.empty?
  end

  def valid_amount?(amount)
    return false unless amount.is_a?(Numeric)
    return false if amount.is_a?(Float) && (amount.nan? || amount.infinite?)
    amount > 0
  rescue StandardError
    false
  end

  def normalize_item(raw)
    return nil unless raw.is_a?(Hash)

    name     = raw.key?(:name) ? raw[:name] : raw['name']
    price    = raw.key?(:price) ? raw[:price] : raw['price']
    quantity = raw.key?(:quantity) ? raw[:quantity] : raw['quantity']

    return nil if name.nil? || name.to_s.strip.empty?

    price_f = begin
      Float(price)
    rescue StandardError
      0.0
    end
    price_f = 0.0 if price_f.nan? || price_f.infinite? || price_f < 0

    qty_i = begin
      Integer(quantity)
    rescue StandardError
      begin
        quantity.is_a?(Numeric) ? quantity.to_i : 0
      rescue StandardError
        0
      end
    end
    qty_i = 0 if qty_i < 0

    { name: name, price: price_f, quantity: qty_i }
  end
end