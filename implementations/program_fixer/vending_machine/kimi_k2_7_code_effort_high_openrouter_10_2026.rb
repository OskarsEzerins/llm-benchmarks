class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @balance = 0.0
    @inventory = if items.is_a?(Array)
      items.compact.map do |item|
        next unless item.is_a?(Hash) && item[:name]
        {
          name: item[:name].to_s,
          price: item[:price].to_f,
          quantity: item[:quantity].to_i
        }
      end.compact
    else
      []
    end
  end

  def insert_money(amount)
    if amount.is_a?(Numeric) && amount > 0
      @balance = (@balance + amount.to_f).round(2)
    end
    @balance
  end

  def select_item(name)
    return "Item not found" if name.nil? || name.to_s.empty?
    item = @inventory.find { |i| i[:name] == name.to_s }
    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity] == 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price]

    @balance = (@balance - item[:price]).round(2)
    item[:quantity] -= 1
    "Dispensed #{name}"
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def check_stock(name)
    return 0 if name.nil? || name.to_s.empty?
    item = @inventory.find { |i| i[:name] == name.to_s }
    item ? item[:quantity].to_i : 0
  end

  def restock(name, quantity)
    return if name.nil? || name.to_s.empty?
    return unless quantity.is_a?(Numeric) && quantity > 0

    qty = quantity.to_i
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