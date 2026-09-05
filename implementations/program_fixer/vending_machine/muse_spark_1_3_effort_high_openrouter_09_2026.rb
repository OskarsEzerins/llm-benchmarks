class VendingMachine
  attr_reader :balance, :inventory

  def initialize(items = nil)
    @inventory = []
    if items.is_a?(Array)
      items.each do |item|
        next unless item.is_a?(Hash)
        name = item[:name].nil? ? item["name"] : item[:name]
        next if name.nil?
        raw_price = item.key?(:price) ? item[:price] : item["price"]
        raw_price = 1.25 if raw_price.nil?
        raw_qty = item.key?(:quantity) ? item[:quantity] : item["quantity"]
        raw_qty = 0 if raw_qty.nil?
        @inventory << { name: name, price: raw_price.to_f, quantity: raw_qty.to_i }
      end
    end
    @balance = 0.0
  end

  def insert_money(amount = nil)
    return unless amount.is_a?(Numeric) && amount > 0
    @balance += amount.to_f
  end

  def select_item(label = nil)
    return "Item not found" if label.nil? || (label.respond_to?(:empty?) && label.empty?)
    item = @inventory.find { |i| i[:name] == label }
    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity].to_i <= 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price].to_f
    @balance -= item[:price].to_f
    item[:quantity] = item[:quantity].to_i - 1
    "Dispensed #{label}"
  end

  def return_change
    change = @balance.to_f
    @balance = 0.0
    change
  end

  def check_stock(label = nil)
    return 0 if label.nil?
    item = @inventory.find { |i| i[:name] == label }
    return 0 if item.nil?
    item[:quantity].to_i
  end

  def restock(label = nil, qty = nil)
    return if label.nil? || (label.respond_to?(:empty?) && label.empty?)
    return unless qty.is_a?(Numeric) && qty > 0
    quantity = qty.to_i
    stock = @inventory.find { |i| i[:name] == label }
    if stock
      stock[:quantity] = stock[:quantity].to_i + quantity
    else
      @inventory << { name: label, price: 1.25, quantity: quantity }
    end
  end

  def get_available_items
    @inventory.select { |i| i.is_a?(Hash) && i[:quantity].to_i > 0 }
  end
end