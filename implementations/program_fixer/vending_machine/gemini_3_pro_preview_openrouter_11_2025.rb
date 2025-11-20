class VendingMachine
  def initialize(items = nil)
    @inventory = items || []
    @balance = 0.0
  end

  def insert_money(amount)
    # Validate numeric and positive; handle non-numeric input safely
    return unless amount.is_a?(Numeric) && amount > 0
    @balance += amount.to_f
  end

  def select_item(label)
    # Handle nil or empty name immediately
    return "Item not found" if label.nil? || label == ""

    # Use correct instance variable and hash key
    item = @inventory.find { |i| i[:name] == label }

    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity] == 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price]

    # Deduct from instance variable balance and update item quantity
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

  def restock(label, qty)
    item = @inventory.find { |i| i[:name] == label }
    
    # Ensure quantity is an integer to prevent crashes on invalid input
    quantity_to_add = qty.to_i 

    if item
      item[:quantity] += quantity_to_add
    else
      # Create new item with default price 1.25 as required
      @inventory << { name: label, price: 1.25, quantity: quantity_to_add }
    end
  end

  def get_available_items
    # Fix typo in variable name and use hash access syntax
    @inventory.select { |i| i[:quantity] > 0 }
  end
end