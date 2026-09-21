class VendingMachine
  def initialize(items = nil)
    @inventory = []
    (items || []).each do |item|
      next unless item.is_a?(Hash) && item[:name]
      @inventory << {
        name: item[:name],
        price: item[:price].to_f,
        quantity: item[:quantity].to_i
      }
    end
    @balance = 0.0
  end

  def insert_money(amount)
    return @balance unless amount.is_a?(Numeric) && amount > 0
    @balance += amount.to_f
    @balance
  end

  def select_item(name)
    return 'Item not found' if name.nil? || name.to_s.empty?

    item = @inventory.find { |i| i[:name] == name }
    return 'Item not found' if item.nil?
    return 'Item out of stock' if item[:quantity] == 0
    return 'Insufficient funds. Please insert more money.' if @balance < item[:price]

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
    return 0 if name.nil?
    item = @inventory.find { |i| i[:name] == name }
    item ? item[:quantity] : 0
  end

  def restock(name, quantity)
    return @inventory unless name.is_a?(String) || name.is_a?(Symbol)
    return @inventory unless quantity.is_a?(Integer) && quantity > 0

    item = @inventory.find { |i| i[:name] == name }
    if item
      item[:quantity] += quantity
    else
      @inventory << { name: name, price: 1.25, quantity: quantity }
    end
    @inventory
  end

  def get_available_items
    @inventory.select { |i| i[:quantity] > 0 }
  end
end