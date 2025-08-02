class VendingMachine
  def initialize(items = nil)
    @inventory = items.select { |item|
      item.is_a?(Hash) &&
      item.key?(:name) &&
      item.key?(:price) &&
      item.key?(:quantity) &&
      item[:name].is_a?(String) &&
      item[:price].is_a?(Numeric) &&
      item[:quantity].is_a?(Integer)
    } || []
    @balance = 0.0
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric) && amount > 0
    @balance += amount.to_f
  end

  def select_item(name)
    return "Item not found" if name.nil? || name.strip.empty?

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
    return 0 if name.nil? || name.strip.empty?

    item = @inventory.find { |i| i[:name] == name }
    item ? item[:quantity] : 0
  end

  def restock(name, qty)
    return unless name.is_a?(String) && !name.strip.empty? && qty.is_a?(Integer) && qty > 0

    stock = @inventory.find { |i| i[:name] == name }
    if stock
      stock[:quantity] += qty
    else
      @inventory << { name: name, price: 1.25, quantity: qty }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity] > 0 }
  end

  attr_reader :balance
end