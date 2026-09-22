class VendingMachine
  DEFAULT_RESTOCK_PRICE = 1.25

  def initialize(items = nil)
    @inventory = []
    @balance = 0.0

    return unless items.is_a?(Array)

    items.each do |item|
      next unless item.is_a?(Hash)

      name = item[:name] || item['name']
      price = item[:price] || item['price']
      quantity = item[:quantity] || item['quantity']

      next if name.nil? || name.to_s.strip.empty?
      next unless price.is_a?(Numeric) && price >= 0
      quantity = quantity.is_a?(Numeric) ? quantity.to_i : 0
      quantity = 0 if quantity < 0

      @inventory << { name: name.to_s, price: price.to_f, quantity: quantity }
    end
  end

  def balance
    @balance.to_f
  end

  def insert_money(amount)
    return @balance unless amount.is_a?(Numeric) && amount.real? && amount > 0
    return @balance if amount.respond_to?(:finite?) && !amount.finite?

    @balance = (@balance + amount.to_f).round(2)
  end

  def select_item(label)
    return 'Item not found' if label.nil? || label.to_s.strip.empty?

    item = find_item(label)

    return 'Item not found' if item.nil?
    return 'Item out of stock' if item[:quantity] <= 0
    return 'Insufficient funds. Please insert more money.' if @balance < item[:price]

    @balance = (@balance - item[:price]).round(2).to_f
    item[:quantity] -= 1
    "Dispensed #{item[:name]}"
  end

  def return_change
    change = @balance.to_f
    @balance = 0.0
    change
  end

  def check_stock(label)
    return 0 if label.nil?

    item = find_item(label)
    item ? item[:quantity].to_i : 0
  end

  def restock(label, qty)
    return nil if label.nil? || label.to_s.strip.empty?
    return nil unless qty.is_a?(Numeric) && qty > 0

    qty = qty.to_i
    return nil if qty <= 0

    item = find_item(label)
    if item
      item[:quantity] += qty
    else
      item = { name: label.to_s, price: DEFAULT_RESTOCK_PRICE, quantity: qty }
      @inventory << item
    end
    item[:quantity]
  end

  def get_available_items
    @inventory.select { |i| i[:quantity] > 0 }
  end

  private

  def find_item(label)
    return nil if label.nil?

    @inventory.find { |i| i[:name] == label.to_s }
  end
end