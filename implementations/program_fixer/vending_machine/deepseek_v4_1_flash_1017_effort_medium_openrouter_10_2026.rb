class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @balance = 0.0
    @inventory = []
    return unless items.is_a?(Array)

    items.each do |item|
      next unless item.is_a?(Hash)

      name = item.key?(:name) ? item[:name] : item["name"]
      next if name.nil? || name.to_s.empty?

      price = item.key?(:price) ? item[:price] : item["price"]
      quantity = item.key?(:quantity) ? item[:quantity] : item["quantity"]

      price = price.is_a?(Numeric) ? price.to_f : 0.0
      quantity = quantity.is_a?(Numeric) ? quantity.to_i : 0

      @inventory << { name: name.to_s, price: price, quantity: quantity }
    end
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric) && amount > 0
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
    return "Item out of stock" if item[:quantity].to_i <= 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price].to_f

    @balance = (@balance - item[:price].to_f).to_f
    item[:quantity] = item[:quantity].to_i - 1
    "Dispensed #{name}"
  end

  def check_stock(name)
    return 0 if name.nil? || name.to_s.empty?

    item = @inventory.find { |i| i[:name] == name.to_s }
    item ? item[:quantity].to_i : 0
  end

  def restock(name, quantity)
    return if name.nil? || name.to_s.empty?
    return unless quantity.is_a?(Numeric)

    qty = quantity.to_i
    return if qty <= 0

    item = @inventory.find { |i| i[:name] == name.to_s }
    if item
      item[:quantity] = item[:quantity].to_i + qty
    else
      @inventory << { name: name.to_s, price: 1.25, quantity: qty }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity].to_i > 0 }
  end
end