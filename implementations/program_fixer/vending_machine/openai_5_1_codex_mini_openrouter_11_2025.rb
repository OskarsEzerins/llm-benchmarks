class VendingMachine
  def initialize(items = nil)
    @balance = 0.0
    @inventory = build_inventory(items)
  end

  def balance
    @balance
  end

  def insert_money(amount)
    return unless valid_amount?(amount)

    @balance += amount.to_f
    @balance
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def select_item(name)
    return "Item not found" if name.nil? || name.to_s.strip.empty?

    item = @inventory.find { |i| i[:name] == name }
    return "Item not found" unless item
    return "Item out of stock" if item[:quantity].to_i <= 0

    price = item[:price].to_f
    return "Insufficient funds. Please insert more money." if @balance < price

    @balance -= price
    @balance = @balance.round(2)
    item[:quantity] -= 1
    "Dispensed #{name}"
  end

  def check_stock(name)
    return 0 if name.nil? || name.to_s.strip.empty?

    item = @inventory.find { |i| i[:name] == name }
    item ? item[:quantity].to_i : 0
  end

  def restock(name, quantity)
    return unless name && !name.to_s.strip.empty?
    return unless quantity.is_a?(Numeric) && quantity.to_i > 0

    qty = quantity.to_i
    item = @inventory.find { |i| i[:name] == name }
    if item
      item[:quantity] += qty
    else
      @inventory << { name: name, price: 1.25, quantity: qty }
    end
  end

  def get_available_items
    @inventory.select { |item| item[:quantity].to_i > 0 }
  end

  private

  def build_inventory(items)
    return [] unless items.is_a?(Array)

    items.each_with_object([]) do |item, inventory|
      next unless item.is_a?(Hash)

      name = item[:name] || item["name"]
      price = item[:price] || item["price"]
      quantity = item[:quantity] || item["quantity"]

      next unless name
      price = safe_float(price)
      quantity = safe_integer(quantity)

      next if quantity < 0 || price.nil?

      inventory << { name: name, price: price, quantity: quantity }
    end
  end

  def valid_amount?(amount)
    amount.is_a?(Numeric) && amount.to_f.positive?
  end

  def safe_float(value)
    return nil unless value
    Float(value) rescue nil
  end

  def safe_integer(value)
    return 0 unless value
    Integer(value) rescue 0
  end
end