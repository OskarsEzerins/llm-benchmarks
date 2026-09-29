class VendingMachine
  attr_reader :balance

  DEFAULT_PRICE = 1.25

  def initialize(items = nil)
    @inventory = []
    @balance = 0.0

    if items.is_a?(Array)
      items.each do |item|
        next unless item.is_a?(Hash)

        name = item[:name]
        next if name.nil? || name.to_s.strip.empty?

        price = item[:price]
        quantity = item[:quantity]

        price = price.is_a?(Numeric) && price >= 0 ? price.to_f : DEFAULT_PRICE
        quantity = quantity.is_a?(Numeric) && quantity >= 0 ? quantity.to_i : 0

        @inventory << { name: name, price: price, quantity: quantity }
      end
    end
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
    return if name.nil? || name.to_s.strip.empty?
    return unless quantity.is_a?(Numeric)
    return unless quantity > 0

    quantity = quantity.to_i
    return if quantity <= 0

    item = find_item(name)
    if item
      item[:quantity] += quantity
    else
      @inventory << { name: name, price: DEFAULT_PRICE, quantity: quantity }
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