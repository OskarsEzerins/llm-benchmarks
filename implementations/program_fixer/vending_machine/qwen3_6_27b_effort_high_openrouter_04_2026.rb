class VendingMachine
  def initialize(items = nil)
    @inventory = items || []
    @balance = 0.0
  end

  def insert_money(amount)
    # Only accept positive numeric values
    return unless amount.is_a?(Numeric) && amount > 0
    @balance += amount
  end

  def select_item(name)
    # Handle nil or empty string input gracefully
    if name.nil? || (name.is_a?(String) && name.strip.empty?)
      return "Item not found"
    end

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
    item.nil? ? 0 : item[:quantity]
  end

  def restock(name, quantity)
    # Handle invalid parameters without crashing
    return unless name && quantity.is_a?(Numeric)
    
    # Ensure quantity is treated as integer
    quantity = quantity.to_i
    
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