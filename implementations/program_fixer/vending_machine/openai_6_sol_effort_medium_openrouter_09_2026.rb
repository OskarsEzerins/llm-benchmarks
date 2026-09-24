class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = []

    if items.is_a?(Array)
      items.each do |item|
        next unless item.is_a?(Hash)
        next unless valid_name?(item[:name])
        next unless valid_price?(item[:price])
        next unless item[:quantity].is_a?(Integer) && item[:quantity] >= 0

        @inventory << {
          name: item[:name],
          price: item[:price].to_f,
          quantity: item[:quantity]
        }
      end
    end

    @balance = 0.0
  end

  def insert_money(amount)
    return unless valid_positive_number?(amount)

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
    return "Item not found" unless item
    return "Item out of stock" if item[:quantity] == 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price]

    @balance -= item[:price]
    item[:quantity] -= 1
    "Dispensed #{name}"
  end

  def check_stock(name)
    return 0 unless valid_name?(name)

    item = @inventory.find { |entry| entry[:name] == name }
    item ? item[:quantity] : 0
  end

  def restock(name, quantity)
    return unless valid_name?(name)
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

  private

  def valid_name?(name)
    name.is_a?(String) && !name.empty?
  end

  def valid_price?(price)
    price.is_a?(Numeric) && !price.is_a?(Complex) &&
      price.to_f.finite? && price >= 0
  end

  def valid_positive_number?(amount)
    amount.is_a?(Numeric) && !amount.is_a?(Complex) &&
      amount.to_f.finite? && amount > 0
  end
end