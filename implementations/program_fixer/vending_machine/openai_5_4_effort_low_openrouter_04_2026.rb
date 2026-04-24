class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = []

    if items.is_a?(Array)
      items.each do |item|
        next unless item.is_a?(Hash)

        name = item[:name]
        next if name.nil? || name.to_s.empty?

        price = item[:price].is_a?(Numeric) ? item[:price].to_f : 0.0
        quantity = item[:quantity].is_a?(Numeric) ? item[:quantity].to_i : 0

        @inventory << {
          name: name,
          price: price,
          quantity: quantity
        }
      end
    end

    @balance = 0.0
  end

  def insert_money(amount)
    return @balance unless amount.is_a?(Numeric) && amount > 0

    @balance += amount.to_f
  end

  def select_item(name)
    return "Item not found" if name.nil? || name.to_s.empty?

    item = @inventory.find { |i| i[:name] == name }
    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity] <= 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price]

    @balance -= item[:price]
    @balance = @balance.to_f
    item[:quantity] -= 1
    "Dispensed #{name}"
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def check_stock(name)
    return 0 if name.nil?

    item = @inventory.find { |i| i[:name] == name }
    item ? item[:quantity].to_i : 0
  end

  def restock(name, quantity)
    return nil if name.nil? || name.to_s.empty?
    return nil unless quantity.is_a?(Numeric) && quantity > 0

    qty = quantity.to_i
    item = @inventory.find { |i| i[:name] == name }

    if item
      item[:quantity] += qty
    else
      @inventory << { name: name, price: 1.25, quantity: qty }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity] > 0 }
  end
end