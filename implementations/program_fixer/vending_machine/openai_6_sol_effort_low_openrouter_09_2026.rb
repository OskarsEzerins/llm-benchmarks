class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = []
    @balance = 0.0

    Array(items).each do |item|
      next unless item.is_a?(Hash)

      name = item[:name]
      price = item[:price]
      quantity = item[:quantity]
      next unless name.is_a?(String) && !name.empty?
      next unless price.is_a?(Numeric) && price.finite? && price >= 0
      next unless quantity.is_a?(Integer) && quantity >= 0

      @inventory << { name: name, price: price.to_f, quantity: quantity }
    end
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric) && amount.finite? && amount > 0

    @balance += amount.to_f
  end

  def select_item(name)
    return "Item not found" unless name.is_a?(String) && !name.empty?

    item = @inventory.find { |entry| entry[:name] == name }
    return "Item not found" unless item
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
    item = @inventory.find { |entry| entry[:name] == name } unless name.nil?
    item ? item[:quantity] : 0
  end

  def restock(name, quantity)
    return unless name.is_a?(String) && !name.empty?
    return unless quantity.is_a?(Integer) && quantity > 0

    item = @inventory.find { |entry| entry[:name] == name }
    if item
      item[:quantity] += quantity
    else
      @inventory << { name: name, price: 1.25, quantity: quantity }
    end
  end

  def get_available_items
    @inventory.select { |item| item[:quantity] > 0 }
  end
end