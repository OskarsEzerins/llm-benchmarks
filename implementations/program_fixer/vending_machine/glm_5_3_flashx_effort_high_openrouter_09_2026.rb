class VendingMachine
  def initialize(items = nil)
    @inventory = Array(items).compact.select { |i| i.is_a?(Hash) }
    @balance = 0.0
  end

  def balance
    @balance
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric)
    return unless amount > 0
    @balance += amount.to_f
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def select_item(label)
    return 'Item not found' if label.nil? || label.to_s.strip.empty?

    item = @inventory.find { |i| i[:name] == label }
    return 'Item not found' if item.nil?
    return 'Item out of stock' if item[:quantity] <= 0

    if @balance < item[:price]
      return 'Insufficient funds. Please insert more money.'
    end

    @balance -= item[:price].to_f
    item[:quantity] -= 1
    "Dispensed #{label}"
  end

  def check_stock(label)
    return 0 if label.nil?

    item = @inventory.find { |i| i[:name] == label }
    item ? item[:quantity].to_i : 0
  end

  def restock(label, qty)
    return if label.nil? || !qty.is_a?(Numeric) || qty <= 0

    qty = qty.to_i
    item = @inventory.find { |i| i[:name] == label }
    if item
      item[:quantity] += qty
    else
      @inventory << { name: label, price: 1.25, quantity: qty }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity].to_i > 0 }
  end
end