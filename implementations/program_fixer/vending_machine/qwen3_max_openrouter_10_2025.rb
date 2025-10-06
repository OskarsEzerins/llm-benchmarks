class VendingMachine
  def initialize(items = nil)
    @inventory = items || []
    @balance   = 0.0
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric) && amount > 0
    @balance += amount.to_f
  end

  def select_item(label)
    return "Item not found" if label.nil? || label == ""
    
    item = @inventory.find { |i| i[:name] == label }
    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity] == 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price]

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
    return 0 if label.nil?
    
    item = @inventory.find { |i| i[:name] == label }
    item ? item[:quantity] : 0
  end

  def restock(label, quantity)
    return if label.nil? || !quantity.is_a?(Integer) || quantity < 0
    
    item = @inventory.find { |i| i[:name] == label }
    if item
      item[:quantity] += quantity
    else
      @inventory << { name: label, price: 1.25, quantity: quantity }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity] > 0 }
  end

  attr_reader :balance
end