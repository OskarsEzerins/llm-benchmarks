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

      next if name.nil? || (name.respond_to?(:empty?) && name.empty?)
      next unless price.is_a?(Numeric) && quantity.is_a?(Numeric)

      @inventory << {
        name: name,
        price: price.to_f,
        quantity: [quantity.to_i, 0].max
      }
    end
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric)

    value = amount.to_f
    return unless value.finite? && value > 0

    @balance += value
  end

  def select_item(name)
    return "Item not found" if name.nil? || (name.respond_to?(:empty?) && name.empty?)

    item = @inventory.find { |entry| entry[:name] == name }

    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity] <= 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price]

    @balance -= item[:price]
    @balance = @balance.round(10)
    item[:quantity] -= 1

    "Dispensed #{name}"
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def check_stock(name)
    return 0 if name.nil? || (name.respond_to?(:empty?) && name.empty?)

    item = @inventory.find { |entry| entry[:name] == name }
    item ? item[:quantity] : 0
  end

  def restock(name, quantity)
    return if name.nil? || (name.respond_to?(:empty?) && name.empty?)
    return unless quantity.is_a?(Numeric)

    amount = quantity.to_i
    return if amount <= 0

    item = @inventory.find { |entry| entry[:name] == name }

    if item
      item[:quantity] += amount
    else
      @inventory << {
        name: name,
        price: 1.25,
        quantity: amount
      }
    end
  end

  def get_available_items
    @inventory.select { |item| item[:quantity] > 0 }
  end
end