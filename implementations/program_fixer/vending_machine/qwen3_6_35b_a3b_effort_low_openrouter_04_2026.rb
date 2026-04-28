class VendingMachine
  def initialize(items = nil)
    @inventory = (items || []).select { |item| item.is_a?(Hash) }
    @balance = 0.0
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric) && amount > 0
    @balance += amount.to_f
  end

  def select_item(label)
    return "Item not found" if label.nil? || label.to_s.empty?

    item = @inventory.find { |i| i[:name] == label }

    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity] == 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price]

    @balance -= item[:price].to_f
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
    item = @inventory.find { |i| i[:name] == label }
    item ? item[:quantity].to_i : 0
  end

  def restock(label, qty)
    return unless label && qty.is_a?(Numeric)
    stock = @inventory.find { |i| i[:name] == label }
    if stock
      stock[:quantity] += qty.to_i
    else
      @inventory << { name: label, price: 1.25, quantity: qty.to_i }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity].to_i > 0 }
  end
end