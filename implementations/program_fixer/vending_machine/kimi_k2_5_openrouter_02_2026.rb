class VendingMachine
  attr_reader :balance
  
  def initialize(items = nil)
    @inventory = items || []
    @balance = 0.0
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric) && amount > 0
    @balance += amount.to_f
  end

  def select_item(name)
    return "Item not found" if name.nil? || name.to_s.empty?
    
    item = @inventory.find { |i| i[:name] == name }
    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity].to_i == 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price].to_f
    
    @balance -= item[:price]
    item[:quantity] = item[:quantity].to_i - 1
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
    item ? item[:quantity].to_i : 0
  end

  def restock(name, quantity)
    return if name.nil? || name.to_s.empty?
    return unless quantity.is_a?(Numeric) && quantity >= 0
    
    item = @inventory.find { |i| i[:name] == name }
    if item
      item[:quantity] = item[:quantity].to_i + quantity.to_i
    else
      @inventory << { name: name, price: 1.25, quantity: quantity.to_i }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity].to_i > 0 }
  end
end