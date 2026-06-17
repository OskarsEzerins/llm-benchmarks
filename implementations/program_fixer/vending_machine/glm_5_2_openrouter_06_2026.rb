class VendingMachine
  def initialize(items = nil)
    @inventory = items || []
    @inventory = [] unless @inventory.is_a?(Array)
    @balance = 0.0
  end

  def insert_money(amount)
    return false unless amount.is_a?(Numeric) && amount > 0
    @balance += amount.to_f
    true
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def select_item(label)
    return "Item not found" if label.nil? || label.to_s.empty?

    item = @inventory.find { |i| i[:name] == label }

    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity] == 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price]

    @balance = @balance - item[:price]
    item[:quantity] -= 1
    "Dispensed #{label}"
  end

  def check_stock(label)
    return 0 if label.nil?
    thing = @inventory.find { |i| i[:name] == label }
    thing ? thing[:quantity] : 0
  end

  def restock(label, quantity)
    return false if label.nil? || !quantity.is_a?(Integer) || quantity <= 0

    stock = @inventory.find { |i| i[:name] == label }
    if stock
      stock[:quantity] += quantity
    else
      @inventory << { name: label, price: 1.25, quantity: quantity }
    end
    true
  end

  def get_available_items
    @inventory.select { |i| i[:quantity] > 0 }
  end
end