class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = []
    @balance = 0.0

    if items.is_a?(Array)
      items.each do |item_hash|
        if item_hash.is_a?(Hash) && item_hash.key?(:name) && item_hash.key?(:price) && item_hash.key?(:quantity)
          @inventory << {
            name: item_hash[:name].to_s,
            price: Float(item_hash[:price] || 0.0),
            quantity: Integer(item_hash[:quantity] || 0)
          }
        end
      end
    end
  end

  def insert_money(amount)
    if amount.is_a?(Numeric) && amount > 0
      @balance += Float(amount)
    end
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def select_item(name)
    return "Item not found" if name.nil? || name.empty?

    item = @inventory.find { |i| i[:name] == name }

    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity] <= 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price]

    @balance -= item[:price]
    item[:quantity] -= 1
    "Dispensed #{name}"
  end

  def check_stock(name)
    return 0 if name.nil?

    item = @inventory.find { |i| i[:name] == name }
    item ? item[:quantity] : 0
  end

  def restock(name, quantity)
    return unless name.is_a?(String) && !name.empty? && quantity.is_a?(Integer) && quantity > 0

    stock = @inventory.find { |i| i[:name] == name }
    if stock
      stock[:quantity] += quantity
    else
      @inventory << { name: name, price: 1.25, quantity: quantity }
    end
  end

  def get_available_items
    @inventory.select { |i| i[:quantity] > 0 }
  end
end