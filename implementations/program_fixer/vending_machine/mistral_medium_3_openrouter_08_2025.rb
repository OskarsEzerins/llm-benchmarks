class VendingMachine
  def initialize(items = nil)
    @inventory = []
    if items.is_a?(Array)
      items.each do |item|
        if item.is_a?(Hash) && item[:name] && item[:price] && item[:quantity]
          @inventory << {
            name: item[:name].to_s,
            price: item[:price].to_f,
            quantity: item[:quantity].to_i
          }
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
    return "Item not found" if name.nil? || name.to_s.strip.empty?

    item = @inventory.find { |i| i[:name] == name.to_s }
    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity] <= 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price]

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
    item = @inventory.find { |i| i[:name] == name.to_s }
    item ? item[:quantity] : 0
  end

  def restock(name, quantity)
    return unless name && quantity.is_a?(Numeric) && quantity > 0
    quantity = quantity.to_i

    item = @inventory.find { |i| i[:name] == name.to_s }
    if item
      item[:quantity] += quantity
    else
      @inventory << { name: name.to_s, price: 1.25, quantity: quantity }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity] > 0 }
  end
end