class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = []
    @balance = 0.0

    return unless items.is_a?(Array)

    items.each do |item|
      next unless item.is_a?(Hash)

      name = item[:name]
      next if name.nil? || name.to_s.empty?

      price = item[:price].is_a?(Numeric) ? item[:price].to_f : 0.0
      quantity = item[:quantity].is_a?(Numeric) ? item[:quantity].to_i : 0
      quantity = 0 if quantity.negative?

      @inventory << {
        name: name,
        price: price,
        quantity: quantity
      }
    end
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric)
    return unless amount.positive?
    return if amount.respond_to?(:finite?) && !amount.finite?

    @balance = (@balance + amount.to_f).to_f
  end

  def select_item(name)
    return "Item not found" if name.nil? || name.to_s.empty?

    item = @inventory.find { |i| i[:name] == name }

    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity].to_i <= 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price].to_f

    @balance = (@balance - item[:price].to_f).to_f
    item[:quantity] = item[:quantity].to_i - 1

    "Dispensed #{name}"
  end

  def return_change
    change = @balance.to_f
    @balance = 0.0
    change
  end

  def check_stock(name)
    return 0 if name.nil?

    item = @inventory.find { |i| i[:name] == name }
    item ? item[:quantity].to_i : 0
  end

  def restock(name, quantity)
    return if name.nil? || name.to_s.empty?
    return unless quantity.is_a?(Numeric)

    quantity = quantity.to_i
    return unless quantity.positive?

    item = @inventory.find { |i| i[:name] == name }

    if item
      item[:quantity] = item[:quantity].to_i + quantity
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
end