class VendingMachine
  attr_reader :balance

  def initialize(items = [])
    @inventory = []
    Array(items).each do |item|
      next unless valid_item_hash?(item)

      @inventory << {
        name:     item[:name].to_s,
        price:    item[:price].to_f,
        quantity: item[:quantity].to_i
      }
    end
    @balance = 0.0
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric) && amount > 0

    @balance += amount.to_f
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def select_item(name)
    return "Item not found" if name.nil? || name.to_s.strip.empty?

    item = @inventory.find { |i| i[:name] == name }
    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity] <= 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price]

    @balance -= item[:price]
    item[:quantity] -= 1
    "Dispensed #{name}"
  end

  def check_stock(name)
    return 0 if name.nil? || name.to_s.strip.empty?

    item = @inventory.find { |i| i[:name] == name }
    item ? item[:quantity] : 0
  end

  def restock(name, quantity)
    return if name.nil? || name.to_s.strip.empty?
    return unless quantity.is_a?(Numeric) && quantity.to_i.positive?

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

  private

  def valid_item_hash?(hash)
    return false unless hash.is_a?(Hash)
    return false unless hash.key?(:name) && (hash[:name].is_a?(String) || hash[:name].is_a?(Symbol))
    return false unless hash.key?(:price) && hash[:price].is_a?(Numeric)
    return false unless hash.key?(:quantity) && hash[:quantity].is_a?(Numeric)

    true
  end
end