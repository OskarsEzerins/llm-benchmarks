class VendingMachine
  def initialize(items = nil)
    @inventory = items.is_a?(Array) ? items : []
    @balance = 0.0
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric) && amount > 0
    @balance += amount
  end

  def select_item(label)
    return 'Item not found' if label.nil? || label.empty?

    item = @inventory.find { |i| i[:name] == label }
    return 'Item not found' if item.nil?
    return 'Item out of stock' if item[:quantity] == 0
    return 'Insufficient funds. Please insert more money.' if @balance < item[:price]

    @balance -= item[:price]
    item[:quantity] -= 1
    "Dispensed #{item[:name]}"
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def check_stock(label)
    return 0 if label.nil? || label.empty?

    item = @inventory.find { |i| i[:name] == label }
    item ? item[:quantity] : 0
  end

  def restock(label, qty)
    return if label.nil? || label.empty? || !qty.is_a?(Integer) || qty <= 0

    stock = @inventory.find { |i| i[:name] == label }
    if stock
      stock[:quantity] += qty
    else
      @inventory << { name: label, price: 1.25, quantity: qty }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity] > 0 }
  end
end