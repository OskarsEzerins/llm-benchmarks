class VendingMachine
  attr_reader :balance, :inventory

  def initialize(items = nil)
    @inventory = []
    @balance = 0.0

    if items.is_a?(Array)
      items.each do |item|
        next unless item.is_a?(Hash)

        name = item[:name] || item['name']
        next if name.nil? || name.to_s.strip.empty?

        price = item[:price] || item['price']
        quantity = item[:quantity] || item['quantity']

        @inventory << {
          name: name.to_s,
          price: price.is_a?(Numeric) ? price.to_f : 0.0,
          quantity: quantity.is_a?(Numeric) && quantity >= 0 ? quantity.to_i : 0
        }
      end
    end
  end

  def insert_money(amount)
    return @balance unless amount.is_a?(Numeric)
    return @balance if amount.respond_to?(:nan?) && amount.nan?
    return @balance unless amount > 0

    @balance += amount.to_f
    @balance
  end

  def select_item(name)
    return 'Item not found' if name.nil? || name.to_s.strip.empty?

    item = find_item(name)

    return 'Item not found' if item.nil?
    return 'Item out of stock' if item[:quantity] <= 0
    return 'Insufficient funds. Please insert more money.' if @balance < item[:price]

    @balance = (@balance - item[:price]).to_f
    item[:quantity] -= 1
    "Dispensed #{item[:name]}"
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
    return false if name.nil? || name.to_s.strip.empty?
    return false unless quantity.is_a?(Integer) && quantity > 0

    item = find_item(name)
    if item
      item[:quantity] += quantity
    else
      @inventory << { name: name.to_s, price: 1.25, quantity: quantity }
    end
    true
  end

  def get_available_items
    @inventory.select { |i| i[:quantity] > 0 }
  end

  private

  def find_item(name)
    @inventory.find { |i| i[:name] == name.to_s }
  end
end