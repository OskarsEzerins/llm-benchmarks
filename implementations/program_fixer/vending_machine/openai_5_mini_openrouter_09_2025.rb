class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = []
    if items.is_a?(Array)
      items.each do |it|
        next unless it.is_a?(Hash)
        name = it[:name] || it['name']
        next if name.nil?
        price = it[:price] || it['price'] || 1.25
        quantity = it[:quantity] || it['quantity'] || 0

        # Normalize types
        name = name.to_s
        price = begin Float(price) rescue 1.25 end
        quantity = begin Integer(quantity) rescue 0 end

        @inventory << { name: name, price: price.to_f, quantity: quantity.to_i }
      end
    end
    @balance = 0.0
  end

  def insert_money(amount)
    return nil unless amount.is_a?(Numeric) && amount > 0
    @balance += amount.to_f
    @balance
  end

  def select_item(name)
    return 'Item not found' if name.nil? || (name.respond_to?(:empty?) && name.empty?)

    item = @inventory.find { |i| i[:name] == name.to_s }
    return 'Item not found' if item.nil?
    return 'Item out of stock' if item[:quantity].to_i <= 0
    return 'Insufficient funds. Please insert more money.' if @balance < item[:price]

    # Successful purchase
    item[:quantity] = item[:quantity].to_i - 1
    @balance = (@balance - item[:price]).to_f
    "Dispensed #{name}"
  end

  def return_change
    change = @balance.to_f
    @balance = 0.0
    change
  end

  def check_stock(name)
    return 0 if name.nil? || (name.respond_to?(:empty?) && name.empty?)
    item = @inventory.find { |i| i[:name] == name.to_s }
    item ? item[:quantity].to_i : 0
  end

  def restock(name, qty)
    return nil if name.nil? || (name.respond_to?(:empty?) && name.empty?)
    return nil unless qty.is_a?(Numeric) && qty > 0

    qty = qty.to_i
    item = @inventory.find { |i| i[:name] == name.to_s }
    if item
      item[:quantity] = item[:quantity].to_i + qty
    else
      @inventory << { name: name.to_s, price: 1.25, quantity: qty }
    end
    true
  end

  def get_available_items
    @inventory.select { |i| i[:quantity].to_i > 0 }
  end
end