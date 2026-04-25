class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @balance = 0.0
    @inventory = []

    return unless items.is_a?(Array)

    items.each do |item|
      next unless item.is_a?(Hash)

      name = item[:name] || item["name"]
      next if name.nil? || (name.respond_to?(:empty?) && name.empty?)

      price = item[:price] || item["price"] || 0.0
      quantity = item[:quantity] || item["quantity"] || 0

      @inventory << {
        name: name,
        price: numeric?(price) ? price.to_f : 0.0,
        quantity: numeric?(quantity) ? quantity.to_i : 0
      }
    end
  end

  def insert_money(amount)
    return unless numeric?(amount) && amount.positive?

    @balance += amount.to_f
  end

  def select_item(name)
    return "Item not found" if name.nil? || (name.respond_to?(:empty?) && name.empty?)

    item = @inventory.find { |i| i[:name] == name }

    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity] <= 0
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
    return 0 if name.nil?

    item = @inventory.find { |i| i[:name] == name }
    item ? item[:quantity].to_i : 0
  end

  def restock(name, quantity)
    return if name.nil? || (name.respond_to?(:empty?) && name.empty?)
    return unless numeric?(quantity) && quantity.positive?

    quantity = quantity.to_i
    item = @inventory.find { |i| i[:name] == name }

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

  def numeric?(value)
    value.is_a?(Numeric) && value.finite?
  end
end