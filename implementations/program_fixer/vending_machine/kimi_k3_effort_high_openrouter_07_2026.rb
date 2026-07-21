class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = []
    @balance = 0.0

    return unless items.is_a?(Array)

    items.each do |item|
      next unless item.is_a?(Hash)

      name = item[:name] || item['name']
      next if name.nil? || name.to_s.empty?

      price = begin
        Float(item[:price] || item['price'] || 0.0)
      rescue
        0.0
      end

      quantity = begin
        Integer(item[:quantity] || item['quantity'] || 0)
      rescue
        0
      end
      quantity = 0 if quantity.negative?

      @inventory << { name: name.to_s, price: price.to_f, quantity: quantity }
    end
  end

  def insert_money(amount)
    return @balance unless amount.is_a?(Numeric)
    return @balance if amount.respond_to?(:finite?) && !amount.finite?
    return @balance unless amount > 0

    @balance = (@balance + amount.to_f).to_f
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def select_item(name)
    item = find_item(name)

    return 'Item not found' if item.nil?
    return 'Item out of stock' if item[:quantity] <= 0
    return 'Insufficient funds. Please insert more money.' if @balance < item[:price]

    @balance = (@balance - item[:price]).to_f
    item[:quantity] -= 1
    "Dispensed #{item[:name]}"
  end

  def check_stock(name)
    item = find_item(name)
    item ? item[:quantity] : 0
  end

  def restock(name, quantity)
    return if name.nil?

    key = name.to_s
    return if key.empty?
    return unless quantity.is_a?(Integer) && quantity > 0

    item = @inventory.find { |i| i[:name] == key }

    if item
      item[:quantity] += quantity
    else
      @inventory << { name: key, price: 1.25, quantity: quantity }
    end
  end

  def get_available_items
    @inventory.select { |item| item[:quantity] > 0 }
  end

  private

  def find_item(name)
    return nil if name.nil?

    key = name.to_s
    return nil if key.empty?

    @inventory.find { |item| item[:name] == key }
  end
end