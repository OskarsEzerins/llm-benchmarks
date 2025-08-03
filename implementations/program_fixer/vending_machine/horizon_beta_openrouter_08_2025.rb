class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = []
    if items.is_a?(Array)
      items.each do |item|
        next unless item.is_a?(Hash)
        name = item[:name]
        price = item[:price]
        quantity = item[:quantity]
        next if name.nil? || name.to_s.strip.empty?
        next unless price.is_a?(Numeric)
        next unless quantity.is_a?(Numeric)
        @inventory << { name: name.to_s, price: price.to_f, quantity: quantity.to_i }
      end
    end
    @balance = 0.0
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric)
    return unless amount > 0
    @balance = (@balance.to_f + amount.to_f)
  end

  def select_item(name)
    return "Item not found" if name.nil? || name.to_s.strip.empty?
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
    return 0 if name.nil? || name.to_s.strip.empty?
    item = @inventory.find { |i| i[:name] == name }
    item ? item[:quantity].to_i : 0
  end

  def restock(name, quantity)
    return unless name.is_a?(String) && !name.strip.empty?
    return unless quantity.is_a?(Numeric) && quantity > 0
    quantity = quantity.to_i
    item = @inventory.find { |i| i[:name] == name }
    if item
      item[:quantity] = item[:quantity].to_i + quantity
    else
      @inventory << { name: name, price: 1.25, quantity: quantity }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity].to_i > 0 }
  end
end