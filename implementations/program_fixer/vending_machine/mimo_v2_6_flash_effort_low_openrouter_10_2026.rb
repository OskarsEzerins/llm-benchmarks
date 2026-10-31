class VendingMachine
  def initialize(items = nil)
    @inventory = items.is_a?(Array) ? items : []
    @inventory = @inventory.select { |i| i.is_a?(Hash) && i[:name] && i[:price] && i[:quantity] }
    @balance = 0.0
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric) && amount > 0
    @balance += amount.to_f
  end

  def select_item(label)
    return 'Item not found' if label.nil? || label.to_s.empty?
    item = @inventory.find { |i| i[:name] == label }

    return 'Item not found' if item.nil?
    return 'Item out of stock' if item[:quantity] == 0
    return 'Insufficient funds. Please insert more money.' if @balance < item[:price]

    @balance -= item[:price]
    item[:quantity] -= 1
    "Dispensed #{label}"
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def check_stock(label)
    return 0 if label.nil? || label.to_s.empty?
    item = @inventory.find { |i| i[:name] == label }
    item ? item[:quantity].to_i : 0
  end

  def restock(label, quantity)
    return unless label && label.to_s.length > 0
    return unless quantity.is_a?(Numeric) && quantity > 0

    existing = @inventory.find { |i| i[:name] == label }
    if existing
      existing[:quantity] += quantity.to_i
    else
      @inventory << { name: label, price: 1.25, quantity: quantity.to_i }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity] > 0 }
  end
end