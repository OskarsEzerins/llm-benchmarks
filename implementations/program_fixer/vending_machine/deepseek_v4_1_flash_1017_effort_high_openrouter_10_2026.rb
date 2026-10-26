class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = []
    @balance = 0.0

    return unless items.is_a?(Array)

    items.each do |item|
      next unless item.is_a?(Hash)

      name = item.key?(:name) ? item[:name] : item["name"]
      price = item.key?(:price) ? item[:price] : item["price"]
      quantity = item.key?(:quantity) ? item[:quantity] : item["quantity"]

      next if name.nil? || name.to_s.empty?
      next unless price.is_a?(Numeric) && !price.is_a?(Complex) && price >= 0
      next unless quantity.is_a?(Numeric) && !quantity.is_a?(Complex) && quantity >= 0
      next unless quantity.to_i == quantity

      @inventory << {
        name: name.to_s,
        price: price.to_f,
        quantity: quantity.to_i
      }
    end
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric)
    return if amount.is_a?(Complex)
    return if amount.respond_to?(:finite?) && !amount.finite?
    return unless amount > 0

    @balance = (@balance + amount.to_f).to_f
  end

  def return_change
    change = @balance.to_f
    @balance = 0.0
    change
  end

  def select_item(name)
    return "Item not found" if name.nil? || name.to_s.empty?

    item = @inventory.find { |i| i[:name] == name.to_s }
    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity] <= 0

    return "Insufficient funds. Please insert more money." if @balance < item[:price]

    @balance = (@balance - item[:price]).to_f
    item[:quantity] -= 1
    "Dispensed #{name}"
  end

  def check_stock(name)
    return 0 if name.nil? || name.to_s.empty?

    item = @inventory.find { |i| i[:name] == name.to_s }
    item ? item[:quantity].to_i : 0
  end

  def restock(name, quantity)
    return if name.nil? || name.to_s.empty?
    return unless quantity.is_a?(Numeric) && !quantity.is_a?(Complex) && quantity > 0
    return unless quantity.to_i == quantity

    quantity = quantity.to_i
    item = @inventory.find { |i| i[:name] == name.to_s }

    if item
      item[:quantity] = item[:quantity].to_i + quantity
    else
      @inventory << { name: name.to_s, price: 1.25, quantity: quantity }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity].to_i > 0 }
  end
end