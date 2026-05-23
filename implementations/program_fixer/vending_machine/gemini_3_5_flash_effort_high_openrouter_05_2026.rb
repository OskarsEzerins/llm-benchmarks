class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @balance = 0.0
    @inventory = []
    
    if items.is_a?(Array)
      items.each do |item|
        next unless item.is_a?(Hash)
        name = item[:name] || item["name"]
        next if name.nil? || name.to_s.strip.empty?
        
        price = item[:price] || item["price"]
        price = price.is_a?(Numeric) ? price.to_f : 0.0
        
        qty = item[:quantity] || item["quantity"]
        qty = qty.is_a?(Numeric) ? qty.to_i : 0
        
        @inventory << { name: name, price: price, quantity: qty }
      end
    end
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric) && amount > 0
    @balance += amount.to_f
  end

  def select_item(label)
    return "Item not found" if label.nil? || label.to_s.strip.empty?
    
    item = @inventory.find { |i| i[:name] == label }
    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity] <= 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price]

    @balance -= item[:price]
    item[:quantity] -= 1
    "Dispensed #{label}"
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def check_stock(label)
    return 0 if label.nil? || label.to_s.strip.empty?
    item = @inventory.find { |i| i[:name] == label }
    item ? item[:quantity].to_i : 0
  end

  def restock(label, qty)
    return if label.nil? || label.to_s.strip.empty?
    return unless qty.is_a?(Numeric)
    qty = qty.to_i
    return if qty <= 0

    item = @inventory.find { |i| i[:name] == label }
    if item
      item[:quantity] += qty
    else
      @inventory << { name: label, price: 1.25, quantity: qty }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity] > 0 }
  end
end