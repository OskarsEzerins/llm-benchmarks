class VendingMachine
  def initialize(items = nil)
    @inventory = []
    if items.is_a?(Array)
      items.each do |item|
        next unless item.is_a?(Hash)
        name  = item[:name]
        price = item[:price]
        qty   = item[:quantity]
        next if name.nil? || name.to_s.empty?
        next unless price.is_a?(Numeric)
        next unless qty.respond_to?(:to_i)
        int_qty = qty.to_i
        next if int_qty < 0
        @inventory << {
          name:     name.to_s,
          price:    price.to_f,
          quantity: int_qty
        }
      end
    end
    @balance = 0.0
  end

  def insert_money(amount)
    if amount.is_a?(Numeric) && amount > 0
      @balance += amount.to_f
    end
  end

  def select_item(name)
    return "Item not found" if name.nil? || name.to_s.empty?

    item = @inventory.find { |i| i[:name] == name }
    return "Item not found" if item.nil?

    return "Item out of stock" if item[:quantity] == 0

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
    return 0 if name.nil? || name.to_s.empty?

    item = @inventory.find { |i| i[:name] == name }
    item ? item[:quantity].to_i : 0
  end

  def restock(name, quantity)
    return if name.nil? || name.to_s.empty?
    return unless quantity.respond_to?(:to_i)

    qty = quantity.to_i
    return if qty <= 0

    item = @inventory.find { |i| i[:name] == name }
    if item
      item[:quantity] += qty
    else
      @inventory << { name: name.to_s, price: 1.25, quantity: qty }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity] > 0 }
  end
end