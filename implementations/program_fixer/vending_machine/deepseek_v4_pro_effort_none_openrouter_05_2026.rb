class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = []
    @balance = 0.0
    
    return if items.nil? || !items.is_a?(Array)
    
    items.each do |item|
      next unless item.is_a?(Hash)
      name = item[:name]
      price = item[:price]
      quantity = item[:quantity]
      
      next if name.nil? || name.to_s.empty?
      price = price.is_a?(Numeric) ? price.to_f : 1.25
      quantity = quantity.is_a?(Integer) ? quantity : 0
      
      @inventory << { name: name, price: price, quantity: quantity }
    end
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric) && amount > 0
    @balance += amount.to_f
  end

  def select_item(label)
    return "Item not found" if label.nil? || label.to_s.empty?
    
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
    return 0 if label.nil? || label.to_s.empty?
    
    item = @inventory.find { |i| i[:name] == label }
    item ? item[:quantity] : 0
  end

  def restock(label, quantity)
    return if label.nil? || label.to_s.empty?
    return unless quantity.is_a?(Integer) && quantity > 0
    
    existing = @inventory.find { |i| i[:name] == label }
    if existing
      existing[:quantity] += quantity
    else
      @inventory << { name: label, price: 1.25, quantity: quantity }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity] > 0 }
  end
end