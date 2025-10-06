class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = items || []
    @balance = 0.0
  end

  def insert_money(amount)
    return if amount.nil?
    num = amount.to_f
    return unless num > 0
    @balance += num
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

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def check_stock(name)
    return 0 if name.nil?
    item = @inventory.find { |i| i[:name] == name }
    item ? item[:quantity] : 0
  end

  def restock(name, quantity)
    return if name.nil? || name.to_s.strip.empty?
    num_qty = quantity.to_i
    return unless num_qty > 0
    item = @inventory.find { |i| i[:name] == name }
    if item
      item[:quantity] += num_qty
    else
      @inventory << { name: name, price: 1.25, quantity: num_qty }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity] > 0 }
  end
end