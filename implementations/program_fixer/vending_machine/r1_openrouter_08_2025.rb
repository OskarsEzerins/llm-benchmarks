class VendingMachine
  attr_reader :balance

  def initialize(items = [])
    @inventory = []
    items = items.is_a?(Array) ? items : []
    items.each do |item|
      next unless item.is_a?(Hash)
      next unless item.key?(:name) && item.key?(:price) && item.key?(:quantity)

      name = item[:name]
      price = item[:price]
      quantity = item[:quantity]
      next unless name.is_a?(String) && !name.empty?
      next unless price.is_a?(Numeric) && price.positive?
      next unless quantity.is_a?(Integer) && quantity >= 0

      @inventory << {
        name: name,
        price: price.to_f,
        quantity: quantity
      }
    end
    @balance = 0.0
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric) && amount.positive?
    @balance += amount.to_f
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def select_item(label)
    return 'Item not found' if label.to_s.empty?

    item = @inventory.find { |i| i[:name] == label }
    return 'Item not found' if item.nil?
    return 'Item out of stock' if item[:quantity] == 0
    return 'Insufficient funds. Please insert more money.' if @balance < item[:price]

    @balance -= item[:price]
    item[:quantity] -= 1
    "Dispensed #{label}"
  end

  def check_stock(name)
    return 0 if name.to_s.empty?

    item = @inventory.find { |i| i[:name] == name }
    item ? item[:quantity] : 0
  end

  def restock(label, quantity)
    return if label.to_s.empty?
    return unless quantity.is_a?(Numeric) && quantity.positive?

    quantity = quantity.to_i
    item = @inventory.find { |i| i[:name] == label }
    if item
      item[:quantity] += quantity
    else
      @inventory << { name: label, price: 1.25, quantity: quantity }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity] > 0 }
  end
end