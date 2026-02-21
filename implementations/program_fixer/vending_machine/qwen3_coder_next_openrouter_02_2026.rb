class VendingMachine
  def initialize(items = nil)
    @inventory = Array(items).select { |item| item.is_a?(Hash) && item[:name] && item[:price] && item[:quantity] }
    @balance = 0.0
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric) && amount > 0
    @balance += amount.to_f
  end

  def select_item(name)
    return "Item not found" unless name.is_a?(String) && !name.empty?
    
    item = @inventory.find { |i| i[:name] == name }
    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity].to_i <= 0
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
    return 0 unless name.is_a?(String) && !name.empty?
    
    item = @inventory.find { |i| i[:name] == name }
    item ? item[:quantity].to_i : 0
  end

  def restock(name, quantity)
    return unless name.is_a?(String) && !name.empty? && quantity.is_a?(Numeric) && quantity > 0
    quantity = quantity.to_i
    
    item = @inventory.find { |i| i[:name] == name }
    if item
      item[:quantity] = (item[:quantity] || 0) + quantity
    else
      @inventory << { name: name, price: 1.25, quantity: quantity }
    end
  end

  def get_available_items
    @inventory.select { |i| (i[:quantity] || 0) > 0 }
  end
end