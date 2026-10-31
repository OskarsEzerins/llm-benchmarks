class VendingMachine
  def initialize(items = nil)
    @inventory = (items || []).select do |i|
      i.is_a?(Hash) && i[:name].is_a?(String) && !i[:name].empty?
    end
    @inventory.each do |item|
      item[:price]    = item[:price].to_f    unless item[:price].is_a?(Float)
      item[:quantity] = item[:quantity].to_i  unless item[:quantity].is_a?(Integer)
      item[:quantity] = 0 if item[:quantity] < 0
      item[:price]    = 0.0 if item[:price] < 0
    end
    @balance = 0.0
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric) && amount > 0
    @balance += amount.to_f
  end

  def select_item(name)
    return 'Item not found' if name.nil? || name.to_s.empty?

    item = @inventory.find { |i| i[:name] == name }

    return 'Item not found' if item.nil?
    return 'Item out of stock' if item[:quantity] <= 0
    return 'Insufficient funds. Please insert more money.' if @balance < item[:price]

    @balance -= item[:price]
    @balance = @balance.round(2) if @balance == @balance.round(2)
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
    item = @inventory.find { |i| i[:name] == name }
    item ? item[:quantity] : 0
  end

  def restock(name, quantity)
    return if name.nil? || name.to_s.empty?
    return unless quantity.is_a?(Numeric) && quantity > 0

    quantity = quantity.to_i
    stock = @inventory.find { |i| i[:name] == name }
    if stock
      stock[:quantity] += quantity
    else
      @inventory << { name: name, price: 1.25, quantity: quantity }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity] > 0 }
  end
end