class VendingMachine
  attr_reader :balance, :inventory

  def initialize(items = nil)
    @balance = 0.0
    @inventory = []
    if items.is_a?(Array)
      items.each do |item|
        next unless item.is_a?(Hash)
        name = item[:name] || item['name']
        next if name.nil? || (name.respond_to?(:empty?) && name.empty?)
        raw_price = item.key?(:price) ? item[:price] : item['price']
        raw_qty = item.key?(:quantity) ? item[:quantity] : item['quantity']
        price = raw_price.is_a?(Numeric) ? raw_price.to_f : 1.25
        quantity = raw_qty.is_a?(Numeric) ? raw_qty.to_i : 0
        @inventory << { name: name, price: price, quantity: quantity }
      end
    end
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric) && amount > 0
    @balance = (@balance + amount.to_f).to_f
  end

  def select_item(name)
    return "Item not found" if name.nil? || (name.respond_to?(:empty?) && name.empty?)
    item = @inventory.find { |i| i[:name] == name }
    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity].to_i <= 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price].to_f
    @balance = (@balance - item[:price].to_f).to_f
    item[:quantity] = item[:quantity].to_i - 1
    "Dispensed #{name}"
  end

  def return_change
    change = @balance.to_f
    @balance = 0.0
    change
  end

  def check_stock(name)
    return 0 if name.nil? || (name.respond_to?(:empty?) && name.empty?)
    item = @inventory.find { |i| i[:name] == name }
    return 0 if item.nil?
    item[:quantity].to_i
  end

  def restock(name, quantity)
    return unless !name.nil? && !(name.respond_to?(:empty?) && name.empty?)
    return unless quantity.is_a?(Numeric) && quantity > 0
    qty = quantity.to_i
    stock = @inventory.find { |i| i[:name] == name }
    if stock
      stock[:quantity] = stock[:quantity].to_i + qty
    else
      @inventory << { name: name, price: 1.25, quantity: qty }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity].to_i > 0 }
  end
end