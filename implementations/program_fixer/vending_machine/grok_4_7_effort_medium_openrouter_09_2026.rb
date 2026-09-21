class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @balance = 0.0
    @inventory = []
    return unless items.is_a?(Array)

    items.each do |item|
      next unless item.is_a?(Hash)

      name = item[:name]
      next if name.nil? || name.to_s.empty?

      item[:price] = item[:price].to_f
      item[:quantity] = item[:quantity].to_i
      @inventory << item
    end
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric) && amount > 0

    @balance += amount.to_f
  end

  def select_item(label)
    return "Item not found" if label.nil? || label.to_s.empty?

    item = @inventory.find { |i| i[:name] == label }
    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity].to_i <= 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price].to_f

    @balance -= item[:price].to_f
    item[:quantity] = item[:quantity].to_i - 1
    "Dispensed #{label}"
  end

  def return_change
    change = @balance.to_f
    @balance = 0.0
    change
  end

  def check_stock(label)
    return 0 if label.nil? || label.to_s.empty?

    thing = @inventory.find { |i| i[:name] == label }
    thing ? thing[:quantity].to_i : 0
  end

  def restock(label, qty)
    return if label.nil? || label.to_s.empty?
    return unless qty.is_a?(Numeric) && qty > 0

    qty = qty.to_i
    return if qty <= 0

    stock = @inventory.find { |i| i[:name] == label }
    if stock
      stock[:quantity] = stock[:quantity].to_i + qty
    else
      @inventory << { name: label, price: 1.25, quantity: qty }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity].to_i > 0 }
  end
end