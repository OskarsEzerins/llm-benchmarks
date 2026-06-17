class VendingMachine
  def initialize(items = nil)
    @inventory = []
    if items.is_a?(Array)
      items.each do |item|
        next unless item.is_a?(Hash) && item[:name] && item[:price] && item[:quantity]
        @inventory << {
          name: item[:name],
          price: item[:price].to_f,
          quantity: item[:quantity].to_i
        }
      end
    end
    @balance = 0.0
  end

  def balance
    @balance
  end

  def insert_money(amount)
    return false unless amount.is_a?(Numeric)
    return false unless amount > 0
    @balance += amount.to_f
    true
  end

  def select_item(label)
    return "Item not found" if label.nil? || label.to_s.empty?

    item = @inventory.find { |i| i[:name] == label }

    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity] == 0
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
    return 0 if label.nil?
    item = @inventory.find { |i| i[:name] == label }
    item ? item[:quantity] : 0
  end

  def restock(label, quantity)
    return if label.nil? || label.to_s.empty?
    return unless quantity.is_a?(Numeric) && quantity > 0

    stock = @inventory.find { |i| i[:name] == label }
    if stock
      stock[:quantity] += quantity.to_i
    else
      @inventory << { name: label, price: 1.25, quantity: quantity.to_i }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity] > 0 }
  end
end