class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = []
    if items.is_a?(Array)
      items.each do |item|
        next unless item.is_a?(Hash)
        name = item[:name] || item["name"]
        price = (item[:price] || item["price"] || 0.0).to_f
        qty = (item[:quantity] || item["quantity"] || 0).to_i
        if name
          @inventory << { name: name.to_s, price: price, quantity: qty }
        end
      end
    end
    @balance = 0.0
  end

  def insert_money(amount)
    return @balance unless amount.is_a?(Numeric) && amount > 0
    @balance += amount.to_f
  end

  def select_item(label)
    return "Item not found" if label.nil? || label.to_s.empty?
    
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
    return 0 if label.nil? || label.to_s.empty?
    thing = @inventory.find { |i| i[:name] == label }
    thing ? thing[:quantity].to_i : 0
  end

  def restock(label, qty)
    return if label.nil? || label.to_s.empty?
    qty = qty.to_i
    return if qty <= 0

    stock = @inventory.find { |i| i[:name] == label }
    if stock
      stock[:quantity] += qty
    else
      @inventory << { name: label.to_s, price: 1.25, quantity: qty }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity] > 0 }
  end
end