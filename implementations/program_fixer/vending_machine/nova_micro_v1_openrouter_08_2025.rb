class VendingMachine
  def initialize(items = nil)
    @inventory = items || []
    @balance = 0.0
  end

  def insert_money(amount)
    return if amount <= 0 || !amount.is_a?(Numeric)
    @balance += amount
  end

  def select_item(name)
    return 'Item not found' if name.nil? || name.empty?
    item = @inventory.find { |i| i[:name] == name }
    return 'Item out of stock' if item.nil? || item[:quantity] == 0
    return 'Insufficient funds. Please insert more money.' if @balance < item[:price]
    @balance -= item[:price]
    item[:quantity] -= 1
    "Dispensed #{name}"
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def check_stock(name)
    item = @inventory.find { |i| i[:name] == name }
    item&.[](:quantity) || 0
  end

  def restock(name, quantity)
    return if quantity <= 0 || !quantity.is_a?(Integer)
    item = @inventory.find { |i| i[:name] == name }
    if item
      item[:quantity] += quantity
    else
      @inventory << { name: name, price: 1.25, quantity: quantity }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity] > 0 }
  end
end