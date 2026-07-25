class VendingMachine
  attr_reader :balance, :inventory

  def initialize(items = nil)
    @inventory = []
    if items.is_a?(Array)
      items.each do |item|
        next unless item.is_a?(Hash)
        name = item[:name]
        next if name.nil? || name.to_s.strip.empty?

        price = item[:price].is_a?(Numeric) ? item[:price].to_f : 0.0
        quantity = item[:quantity].is_a?(Numeric) ? item[:quantity].to_i : 0

        @inventory << { name: name, price: price, quantity: quantity }
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
    return 'Item out of stock' if item[:quantity].to_i <= 0
    return 'Insufficient funds. Please insert more money.' if @balance < item[:price]

    @balance = (@balance - item[:price]).to_f
    item[:quantity] -= 1
    "Dispensed #{label}"
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def check_stock(label)
    return 0 if label.nil? || label.to_s.strip.empty?

    item = @inventory.find { |i| i[:name] == label }
    item ? item[:quantity].to_i : 0
  end

  def restock(label, qty)
    return false if label.nil? || label.to_s.strip.empty?
    return false unless qty.is_a?(Numeric)

    qty = qty.to_i
    return false if qty <= 0

    item = @inventory.find { |i| i[:name] == label }
    if item
      item[:quantity] = item[:quantity].to_i + qty
    else
      @inventory << { name: label, price: 1.25, quantity: qty }
    end
    true
  end

  def get_available_items
    @inventory.select { |i| i[:quantity].to_i > 0 }
  end
end