class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @balance = 0.0
    @inventory = []
    return unless items.is_a?(Array)

    items.each do |raw_item|
      next unless raw_item.is_a?(Hash)

      name = raw_item[:name] || raw_item['name']
      next if name.nil?

      name = name.to_s
      next if name.empty?

      price = raw_item[:price] || raw_item['price']
      quantity = raw_item[:quantity] || raw_item['quantity']

      price_f = safe_float(price)
      next if price_f.nil? || price_f < 0.0

      qty_i = safe_integer(quantity)
      qty_i = 0 if qty_i.nil? || qty_i < 0

      @inventory << {
        name: name,
        price: to_money(price_f),
        quantity: qty_i
      }
    end
  end

  def insert_money(amount)
    amount_f = safe_float(amount)
    return if amount_f.nil? || amount_f <= 0.0

    @balance = to_money(@balance + amount_f)
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def select_item(name)
    return 'Item not found' if name.nil? || name.to_s.empty?

    item = find_item(name)
    return 'Item not found' if item.nil?
    return 'Item out of stock' if item[:quantity].to_i <= 0

    price = item[:price].to_f
    return 'Insufficient funds. Please insert more money.' if @balance < price

    @balance = to_money(@balance - price)
    item[:quantity] = item[:quantity].to_i - 1

    "Dispensed #{item[:name]}"
  end

  def check_stock(name)
    return 0 if name.nil? || name.to_s.empty?

    item = find_item(name)
    item ? item[:quantity].to_i : 0
  end

  def restock(name, quantity)
    return if name.nil?

    name_s = name.to_s
    return if name_s.empty?

    qty = safe_integer(quantity)
    return if qty.nil? || qty <= 0

    item = find_item(name_s)
    if item
      item[:quantity] = item[:quantity].to_i + qty
    else
      @inventory << { name: name_s, price: 1.25, quantity: qty }
    end
  end

  def get_available_items
    @inventory.select { |item| item[:quantity].to_i > 0 }
  end

  private

  def find_item(name)
    name_s = name.to_s
    @inventory.find { |item| item[:name].to_s == name_s }
  end

  def safe_float(value)
    return nil unless value.is_a?(Numeric)

    float = value.to_f
    return nil unless float.finite?

    float
  rescue StandardError
    nil
  end

  def safe_integer(value)
    return nil unless value.is_a?(Numeric)

    integer = value.to_i
    return nil unless value == integer

    integer
  rescue StandardError
    nil
  end

  def to_money(value)
    rounded = value.to_f.round(15)
    rounded.zero? ? 0.0 : rounded
  rescue StandardError
    0.0
  end
end