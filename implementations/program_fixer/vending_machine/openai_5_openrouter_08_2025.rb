class VendingMachine
  attr_reader :balance

  DEFAULT_PRICE = 1.25

  def initialize(items = nil)
    @inventory = sanitize_items(items)
    @balance = 0.0
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric)
    return unless amount > 0
    @balance = (@balance.to_f + amount.to_f)
  end

  def select_item(name)
    return "Item not found" if name.nil? || name.to_s.strip.empty?

    item = @inventory.find { |i| i[:name] == name }
    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity] == 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price]

    @balance = (@balance - item[:price].to_f)
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
    return unless name.is_a?(String) && !name.strip.empty?
    return unless quantity.is_a?(Integer) && quantity > 0

    item = @inventory.find { |i| i[:name] == name }
    if item
      item[:quantity] += quantity
    else
      @inventory << { name: name, price: DEFAULT_PRICE.to_f, quantity: quantity.to_i }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity].to_i > 0 }
  end

  private

  def sanitize_items(items)
    return [] unless items.is_a?(Array)

    items.each_with_object([]) do |it, arr|
      next unless it.is_a?(Hash)
      name = it[:name] || it['name']
      price = it[:price] || it['price']
      quantity = it[:quantity] || it['quantity']

      next if name.nil? || name.to_s.strip.empty?
      next unless price.is_a?(Numeric) && price >= 0
      next unless quantity.is_a?(Numeric) && quantity >= 0

      arr << {
        name: name.to_s,
        price: price.to_f,
        quantity: quantity.to_i
      }
    end
  end
end