class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = items.is_a?(Array) ? items : []
    @balance = 0.0
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric) && amount > 0
    @balance += amount.to_f
  end

  def select_item(name)
    return "Item not found" if name.nil? || name.to_s.empty?

    item = @inventory.find { |i| i.is_a?(Hash) && i[:name] == name }

    return "Item not found" if item.nil?

    quantity = item[:quantity].to_i
    return "Item out of stock" if quantity == 0

    price = item[:price].to_f
    return "Insufficient funds. Please insert more money." if @balance < price

    @balance -= price
    item[:quantity] -= 1
    "Dispensed #{name}"
  end

  def return_change
    current = @balance
    @balance = 0.0
    current
  end

  def check_stock(name)
    return 0 if name.nil?
    item = @inventory.find { |i| i.is_a?(Hash) && i[:name] == name }
    return 0 if item.nil?
    item[:quantity].to_i
  end

  def restock(name, qty)
    return if name.nil? || qty.nil? || !qty.is_a?(Numeric)
    qty = qty.to_i

    item = @inventory.find { |i| i.is_a?(Hash) && i[:name] == name }
    if item
      item[:quantity] = item[:quantity].to_i + qty
    else
      @inventory << { name: name, price: 1.25, quantity: qty }
    end
  end

  def get_available_items
    @inventory.select { |i| i.is_a?(Hash) && i[:quantity].to_i > 0 }
  end
end