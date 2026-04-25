class VendingMachine
  attr_reader :balance, :inventory

  def initialize(items = nil)
    @inventory = []

    if items.is_a?(Array)
      items.each do |item|
        normalized = normalize_item(item)
        @inventory << normalized if normalized
      end
    end

    @balance = 0.0
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric) && amount.positive?

    @balance = (@balance + amount.to_f).to_f
  end

  def return_change
    change = @balance.to_f
    @balance = 0.0
    change
  end

  def select_item(name)
    return "Item not found" if invalid_name?(name)

    item = @inventory.find { |i| i[:name] == name }

    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity] <= 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price]

    @balance = (@balance - item[:price]).to_f
    item[:quantity] = (item[:quantity] - 1).to_i

    "Dispensed #{name}"
  end

  def check_stock(name)
    return 0 if invalid_name?(name)

    item = @inventory.find { |i| i[:name] == name }
    item ? item[:quantity].to_i : 0
  end

  def restock(name, quantity)
    return if invalid_name?(name)
    return unless quantity.is_a?(Numeric) && quantity.positive?

    qty = quantity.to_i
    return if qty <= 0

    item = @inventory.find { |i| i[:name] == name }

    if item
      item[:quantity] = (item[:quantity] + qty).to_i
    else
      @inventory << { name: name, price: 1.25, quantity: qty }
    end
  end

  def get_available_items
    @inventory.select { |item| item[:quantity].to_i > 0 }
  end

  private

  def normalize_item(item)
    return nil unless item.is_a?(Hash)

    name = item[:name]
    price = item[:price]
    quantity = item[:quantity]

    return nil if invalid_name?(name)
    return nil unless price.is_a?(Numeric)

    {
      name: name,
      price: price.to_f,
      quantity: quantity.is_a?(Numeric) ? quantity.to_i : 0
    }
  end

  def invalid_name?(name)
    name.nil? || (name.respond_to?(:empty?) && name.empty?)
  end
end