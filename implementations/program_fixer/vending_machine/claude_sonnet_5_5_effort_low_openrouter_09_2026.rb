class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = []
    if items.is_a?(Array)
      items.each do |i|
        next unless i.is_a?(Hash)
        name = i[:name]
        next if name.nil? || name.to_s.empty?
        price = i[:price].is_a?(Numeric) ? i[:price].to_f : 0.0
        qty = i[:quantity].is_a?(Numeric) ? i[:quantity].to_i : 0
        qty = 0 if qty < 0
        @inventory << { name: name, price: price, quantity: qty }
      end
    end
    @balance = 0.0
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric)
    return unless amount.respond_to?(:finite?) ? amount.finite? : true
    return unless amount > 0
    @balance += amount.to_f
  end

  def select_item(name)
    return 'Item not found' if name.nil? || name.to_s.empty?
    item = find_item(name)

    return 'Item not found' if item.nil?
    return 'Item out of stock' if item[:quantity] <= 0
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
    item = find_item(name)
    item ? item[:quantity].to_i : 0
  end

  def restock(name, quantity)
    return if name.nil? || name.to_s.empty?
    return unless quantity.is_a?(Numeric) && quantity > 0
    quantity = quantity.to_i
    return if quantity <= 0
    stock = find_item(name)
    if stock
      stock[:quantity] += quantity
    else
      @inventory << { name: name, price: 1.25, quantity: quantity }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity] > 0 }
  end

  private

  def find_item(name)
    @inventory.find { |i| i[:name] == name }
  end
end