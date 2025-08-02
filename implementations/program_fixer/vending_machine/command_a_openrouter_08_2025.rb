class VendingMachine
  # Initialize the vending machine with items
  def initialize(items = [])
    @inventory = items.map do |item|
      { name: item[:name], price: item[:price], quantity: item[:quantity] }
    end
  end

  # Insert money into the vending machine
  def insert_money(amount)
    @balance += amount
  end

  # Select an item by name and dispense it if possible
  def select_item(name)
    item = @inventory.find { |i| i[:name] == name }
    if item
      if item[:quantity] > 0
        item[:quantity] -= 1
        @balance -= item[:price]
        "Dispensing: #{item[:name]}\nBalance: $#{sprintf('%.2f', @balance)}"
      else
        "Item out of stock"
      end
    else
      "Item not found"
    end
  end

  # Return the current balance
  def check_balance
    @balance
  end

  # Return the remaining balance after a purchase
  def return_change(amount)
    @balance -= amount
    amount
  end

  # Restock an item
  def restock_item(name, quantity)
    item = @inventory.find { |i| i[:name] == name }
    if item
      item[:quantity] += quantity
    else
      @inventory << { name: name, quantity: quantity }
    end
  end

  # Get the available items
  def get_available_items
    @inventory.select { |item| item[:quantity] > 0 }
  end

  # Get the inventory
  def get_inventory
    @inventory
  end
end