class VendingMachine
  attr_reader :balance, :inventory

  def initialize(items = nil)
    @inventory = []
    if items.is_a?(Array)
      items.each do |item|
        next unless item.is_a?(Hash)
        name = item[:name] || item["name"]
        next if name.nil? || name.to_s.strip.empty?
        price = item[:price] || item["price"] || 0.0
        quantity = item[:quantity] || item["quantity"] || 0
        next unless price.is_a?(Numeric) && quantity.is_a?(Numeric)
        @inventory << { name: name.to_s, price: price.to_f, quantity: quantity.to_i }
      end
    end
    @balance = 0.0
  end

  def insert_money(amount)
    return @balance unless amount.is_a?(Numeric)
    return @balance unless amount > 0
    @balance += amount.to_f
    @balance
  end

  def select_item(label)
    return 'Item not found' if label.nil? || label.to_s.strip.empty?
    item = @inventory.find { |i| i[:name] == label }

    return 'Item not found' if item.nil?
    return 'Item out of stock' if item[:quantity] <= 0
    return 'Insufficient funds. Please insert more money.' if @balance < item[:price]

    @balance = (@balance - item[:price]).round(2)
    item[:quantity] -= 1
    "Dispensed #{label}"
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def check_stock(label)
    return 0 if label.nil?
    thing = @inventory.find { |i| i[:name] == label }
    thing ? thing[:quantity].to_i : 0
  end

  def restock(label, qty)
    return nil if label.nil? || label.to_s.strip.empty?
    return nil unless qty.is_a?(Numeric) && qty > 0
    qty = qty.to_i
    stock = @inventory.find { |i| i[:name] == label }
    if stock
      stock[:quantity] += qty
    else
      @inventory << { name: label, price: 1.25, quantity: qty }
    end
    check_stock(label)
  end

  def get_available_items
    @inventory.select { |i| i[:quantity] > 0 }
  end
end