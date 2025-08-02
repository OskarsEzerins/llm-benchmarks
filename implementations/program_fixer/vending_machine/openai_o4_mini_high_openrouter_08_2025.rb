class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = []
    if items.is_a?(Array)
      items.each do |i|
        next unless i.is_a?(Hash) && i.key?(:name) && i.key?(:price) && i.key?(:quantity)
        name = i[:name].to_s
        price = i[:price].to_f
        qty = i[:quantity].to_i
        @inventory << { name: name, price: price, quantity: qty }
      end
    end
    @balance = 0.0
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric) && amount > 0
    @balance += amount.to_f
    @balance
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def select_item(name)
    return 'Item not found' if name.nil? || (name.respond_to?(:empty?) && name.empty?)
    item = @inventory.find { |i| i[:name] == name }
    return 'Item not found' unless item
    return 'Item out of stock' if item[:quantity] <= 0
    return 'Insufficient funds. Please insert more money.' if @balance < item[:price]
    @balance -= item[:price]
    item[:quantity] -= 1
    "Dispensed #{name}"
  end

  def check_stock(name)
    return 0 if name.nil? || (name.respond_to?(:empty?) && name.empty?)
    item = @inventory.find { |i| i[:name] == name }
    item ? item[:quantity] : 0
  end

  def restock(name, qty)
    return unless name.is_a?(String) && !name.empty?
    return unless qty.is_a?(Numeric)
    qty = qty.to_i
    return if qty <= 0
    item = @inventory.find { |i| i[:name] == name }
    if item
      item[:quantity] += qty
    else
      @inventory << { name: name, price: 1.25, quantity: qty }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity] > 0 }
  end
end