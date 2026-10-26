class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @balance = 0.0
    @inventory = []

    return unless items.is_a?(Array)

    items.each do |item|
      next unless item.is_a?(Hash)

      name = item[:name]
      next if name.nil? || name.to_s.empty?

      price = item[:price]
      price = price.is_a?(Numeric) ? price.to_f : (price.respond_to?(:to_f) ? price.to_f : 0.0)

      quantity = item[:quantity]
      quantity = quantity.to_i if quantity.respond_to?(:to_i)
      quantity = 0 unless quantity.is_a?(Integer)
      quantity = 0 if quantity < 0

      @inventory << { name: name, price: price, quantity: quantity }
    end
  end

  def insert_money(amount)
    return @balance unless amount.is_a?(Numeric) && amount.respond_to?(:>) && amount > 0
    @balance = (@balance + amount).to_f
  end

  def return_change
    change = @balance.to_f
    @balance = 0.0
    change
  end

  def select_item(label)
    return "Item not found" if label.nil? || label.to_s.empty?

    item = @inventory.find { |i| i[:name] == label }
    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity].to_i <= 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price]

    @balance = (@balance - item[:price]).to_f
    item[:quantity] = item[:quantity].to_i - 1
    "Dispensed #{label}"
  end

  def check_stock(label)
    return 0 if label.nil? || label.to_s.empty?

    item = @inventory.find { |i| i[:name] == label }
    item ? item[:quantity].to_i : 0
  end

  def restock(label, quantity)
    return nil if label.nil? || label.to_s.empty?
    return nil unless quantity.is_a?(Integer)
    return nil if quantity <= 0

    item = @inventory.find { |i| i[:name] == label }

    if item
      item[:quantity] = item[:quantity].to_i + quantity
    else
      @inventory << { name: label, price: 1.25, quantity: quantity }
    end
  end

  def get_available_items
    @inventory.select { |item| item[:quantity].to_i > 0 }
  end
end