class VendingMachine
  def initialize(items = nil)
    @inventory = items ? items.map(&:dup) : []
    @balance = 0.0
  end

  def insert_money(amount)
    if amount.is_a?(Numeric) && amount > 0
      @balance += amount.to_f
    end
  end

  def select_item(name)
    return "Item not found" if name.nil? || name.empty?
    item = @inventory.find { |i| i[:name] == name }
    return "Item not found" if item.nil?

    if item[:quantity] == 0
      return "Item out of stock"
    end

    if @balance < item[:price]
      return "Insufficient funds. Please insert more money."
    end

    @balance -= item[:price]
    item[:quantity] -= 1
    return "Dispensed #{name}"
  end

  def return_change
    change = @balance
    @balance = 0.0
    return change
  end

  def check_stock(name)
    return 0 if name.nil?
    item = @inventory.find { |i| i[:name] == name }
    item ? item[:quantity] : 0
  end

  def restock(name, quantity)
    return unless name.is_a?(String) && !name.empty? && quantity.is_a?(Integer) && quantity > 0

    stock = @inventory.find { |i| i[:name] == name }
    if stock
      stock[:quantity] += quantity
    else
      @inventory << { name: name, price: 1.25, quantity: quantity }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity] > 0 }
  end
end