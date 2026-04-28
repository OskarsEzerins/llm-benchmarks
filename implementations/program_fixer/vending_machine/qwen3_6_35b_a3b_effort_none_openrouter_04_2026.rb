class VendingMachine
  def initialize(items = nil)
    items = [] if items.nil?
    @inventory = items.map do |item|
      if item.is_a?(Hash) && item[:name] && item.is_a?(Hash)
        { name: item[:name].to_s, price: item[:price].to_f, quantity: item[:quantity].to_i }
      else
        { name: "", price: 0.0, quantity: 0 }
      end
    end
    @balance = 0.0
  end

  def balance
    @balance
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric)
    return unless amount > 0
    @balance += amount.to_f
  end

  def select_item(label)
    return "Item not found" if label.nil? || label.to_s.empty?
    
    item = @inventory.find { |i| i[:name] == label.to_s }
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
    
    item = @inventory.find { |i| i[:name] == label.to_s }
    return 0 if item.nil?
    item[:quantity].to_i
  end

  def restock(label, qty)
    return if label.nil? || label.to_s.empty?
    return unless qty.is_a?(Numeric) && qty > 0
    qty = qty.to_i
    
    stock = @inventory.find { |i| i[:name] == label.to_s }
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