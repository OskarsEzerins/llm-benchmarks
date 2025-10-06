class VendingMachine
  def initialize(items = [])
    @inventory = []
    items.each { |item| add_item(item) } if items.is_a?(Array)
    @balance = 0.0
  end

  def add_item(item)
    return unless item.is_a?(Hash) && item[:name] && item[:price] && item[:quantity]
    @inventory << {
      name: item[:name].to_s,
      price: item[:price].to_f,
      quantity: item[:quantity].to_i
    }
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric) && amount > 0
    @balance += amount.to_f
  end

  def select_item(name)
    return "Item not found" if name.nil? || name == ""
    
    item = @inventory.find { |i| i[:name] == name }
    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity] <= 0
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
    return unless name && quantity.is_a?(Numeric) && quantity > 0
    
    item = @inventory.find { |i| i[:name] == name }
    if item
      item[:quantity] += quantity.to_i
    else
      @inventory << { name: name, price: 1.25, quantity: quantity.to_i }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity] > 0 }
  end

  attr_reader :balance
end