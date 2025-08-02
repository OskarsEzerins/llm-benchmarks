class VendingMachine
  def initialize(items = [])
    @inventory = items
    @balance = 0.0
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric) && amount > 0
    @balance += amount.to_f
  end

  def select_item(name)
    return "Item not found" if name.nil? || name.empty?
    item = @inventory.find { |i| i[:name] == name }

    if item.nil?
      "Item not found"
    elsif item[:quantity] <= 0
      "Item out of stock"
    elsif @balance < item[:price]
      "Insufficient funds. Please insert more money."
    else
      @balance -= item[:price]
      item[:quantity] -= 1
      "Dispensed #{name}"
    end
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def check_stock(name)
    item = @inventory.find { |i| i[:name] == name }
    item ? item[:quantity] : 0
  end

  def restock(name, quantity)
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