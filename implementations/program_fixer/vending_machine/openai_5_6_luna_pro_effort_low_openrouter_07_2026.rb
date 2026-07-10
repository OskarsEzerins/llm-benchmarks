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

      next unless valid_name?(name)
      next unless price.is_a?(Numeric) && finite_number?(price)
      next unless quantity.is_a?(Numeric) && quantity.to_i == quantity

      @inventory << {
        name: name,
        price: price.to_f,
        quantity: [quantity.to_i, 0].max
      }
    end
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric)
    return unless finite_number?(amount) && amount > 0

    @balance += amount.to_f
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def select_item(name)
    return "Item not found" unless valid_name?(name)

    item = @inventory.find { |entry| entry[:name] == name }
    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity] <= 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price]

    @balance -= item[:price]
    @balance = @balance.to_f
    item[:quantity] -= 1

    "Dispensed #{name}"
  end

  def check_stock(name)
    return 0 unless valid_name?(name)

    item = @inventory.find { |entry| entry[:name] == name }
    item ? item[:quantity].to_i : 0
  end

  def restock(name, quantity)
    return unless valid_name?(name)
    return unless quantity.is_a?(Numeric)
    return unless finite_number?(quantity)
    return unless quantity > 0 && quantity.to_i == quantity

    quantity = quantity.to_i
    item = @inventory.find { |entry| entry[:name] == name }

    if item
      item[:quantity] += quantity
    else
      @inventory << {
        name: name,
        price: 1.25,
        quantity: quantity
      }
    end
  end

  def get_available_items
    @inventory.select { |item| item[:quantity].to_i > 0 }
  end

  private

  def valid_name?(name)
    !name.nil? && (!name.respond_to?(:empty?) || !name.empty?)
  end

  def finite_number?(number)
    !number.respond_to?(:finite?) || number.finite?
  end
end