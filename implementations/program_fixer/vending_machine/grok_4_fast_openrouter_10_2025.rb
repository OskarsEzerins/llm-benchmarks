class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = items || []
    @balance = 0.0
  end

  def insert_money(amount)
    return unless amount.respond_to?(:to_f)
    f = amount.to_f
    return unless f > 0
    @balance += f
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def select_item(name)
    return "Item not found" if name.nil? || name.empty?
    item = @inventory.find { |i| i[:name] == name }
    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity] == 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price]
    @balance -= item[:price]
    item[:quantity] -= 1
    "Dispensed #{name}"
  end

  def check_stock(name)
    return 0 if name.nil? || name.empty?
    item = @inventory.find { |i| i[:name] == name }
    item ? item[:quantity] : 0
  end

  def restock(name, quantity)
    return if name.nil? || name.empty?
    return unless quantity.respond_to?(:to_i)
    qty = quantity.to_i
    return if qty <= 0
    stock = @inventory.find { |i| i[:name] == name }
    if stock
      stock[:quantity] += qty
    else
      @inventory << { name: name, price: 1.25, quantity: qty }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity] > 0 }
  end
end