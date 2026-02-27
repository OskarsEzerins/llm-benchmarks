class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = []
    @balance = 0.0

    return unless items.is_a?(Array)

    items.each do |item|
      next unless item.is_a?(Hash)

      name = item[:name] || item["name"]
      price = item[:price] || item["price"]
      quantity = item[:quantity] || item["quantity"]

      next if name.nil? || name.to_s.strip.empty?

      @inventory << {
        name: name.to_s,
        price: price.to_f,
        quantity: quantity.to_i
      }
    end
  end

  def insert_money(amount)
    return @balance unless amount.is_a?(Numeric)
    return @balance unless amount.positive?

    @balance += amount.to_f
    @balance
  end

  def select_item(name)
    return "Item not found" if name.nil? || name.to_s.strip.empty?

    item = @inventory.find { |i| i[:name] == name.to_s }
    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity].to_i <= 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price].to_f

    @balance -= item[:price].to_f
    item[:quantity] = item[:quantity].to_i - 1
    "Dispensed #{name}"
  end

  def return_change
    change = @balance.to_f
    @balance = 0.0
    change
  end

  def check_stock(name)
    return 0 if name.nil? || name.to_s.strip.empty?

    item = @inventory.find { |i| i[:name] == name.to_s }
    item ? item[:quantity].to_i : 0
  end

  def restock(name, quantity)
    return if name.nil? || name.to_s.strip.empty?
    return unless quantity.is_a?(Numeric)

    qty = quantity.to_i
    return if qty <= 0

    item = @inventory.find { |i| i[:name] == name.to_s }

    if item
      item[:quantity] = item[:quantity].to_i + qty
    else
      @inventory << { name: name.to_s, price: 1.25, quantity: qty }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity].to_i > 0 }
  end
end