class VendingMachine
  def initialize(items = nil)
    @inventory = []
    @balance = 0.0

    return unless items.is_a?(Array)

    items.each do |item|
      next unless item.is_a?(Hash)

      name = item[:name] || item['name']
      next if name.nil? || name.to_s.empty?

      price = item[:price] || item['price'] || 0.0
      quantity = item[:quantity] || item['quantity'] || 0
      quantity = quantity.to_i
      quantity = 0 if quantity < 0

      @inventory << {
        name: name.to_s,
        price: price.to_f,
        quantity: quantity
      }
    end
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric) && amount.real? && amount > 0
    @balance = (@balance + amount).to_f
  end

  def return_change
    change = @balance.to_f
    @balance = 0.0
    change
  end

  def select_item(label)
    return 'Item not found' if label.nil? || label.to_s.empty?

    name = label.to_s
    item = @inventory.find { |i| i[:name] == name }
    return 'Item not found' if item.nil?
    return 'Item out of stock' if item[:quantity].to_i <= 0
    return 'Insufficient funds. Please insert more money.' if @balance < item[:price].to_f

    @balance = (@balance - item[:price]).to_f
    item[:quantity] = item[:quantity].to_i - 1
    "Dispensed #{name}"
  end

  def check_stock(name)
    return 0 if name.nil? || name.to_s.empty?

    item = @inventory.find { |i| i[:name] == name.to_s }
    item ? item[:quantity].to_i : 0
  end

  def restock(name, quantity)
    return nil if name.nil? || name.to_s.empty?
    return nil unless quantity.is_a?(Numeric) && quantity.real? && quantity > 0

    qty = quantity.to_i
    return nil if qty <= 0

    name = name.to_s
    item = @inventory.find { |i| i[:name] == name }
    if item
      item[:quantity] = item[:quantity].to_i + qty
      item
    else
      new_item = { name: name, price: 1.25, quantity: qty }
      @inventory << new_item
      new_item
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity].to_i > 0 }
  end
end