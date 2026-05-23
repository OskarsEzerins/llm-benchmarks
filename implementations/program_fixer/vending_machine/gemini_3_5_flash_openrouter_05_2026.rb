class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = []
    if items.is_a?(Array)
      items.each do |item|
        if item.is_a?(Hash)
          name = item[:name] || item['name']
          price = (item[:price] || item['price'] || 0.0).to_f
          quantity = (item[:quantity] || item['quantity'] || 0).to_i
          @inventory << { name: name, price: price, quantity: quantity } if name
        end
      end
    end
    @balance = 0.0
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric) && amount > 0
    @balance += amount.to_f
  end

  def select_item(name)
    if name.nil? || name.to_s.strip.empty?
      return "Item not found"
    end

    item = @inventory.find { |i| i[:name] == name }
    return "Item not found" unless item

    if item[:quantity] <= 0
      return "Item out of stock"
    end

    if @balance < item[:price]
      return "Insufficient funds. Please insert more money."
    end

    @balance -= item[:price]
    item[:quantity] -= 1
    "Dispensed #{name}"
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def check_stock(name)
    return 0 if name.nil? || name.to_s.strip.empty?
    item = @inventory.find { |i| i[:name] == name }
    item ? item[:quantity].to_i : 0
  end

  def restock(name, quantity)
    return if name.nil? || name.to_s.strip.empty?
    return unless quantity.is_a?(Numeric) && quantity > 0

    qty = quantity.to_i
    stock = @inventory.find { |i| i[:name] == name }
    if stock
      stock[:quantity] += qty
    else
      @inventory << { name: name, price: 1.25, quantity: qty }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity] > 0 }
  end
end