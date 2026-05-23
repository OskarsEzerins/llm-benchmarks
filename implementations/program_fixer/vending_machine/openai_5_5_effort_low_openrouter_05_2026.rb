class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @balance = 0.0
    @inventory = []

    return unless items.is_a?(Array)

    items.each do |item|
      next unless item.is_a?(Hash)

      name = item[:name]
      price = item[:price]
      quantity = item[:quantity]

      next if name.nil? || name.to_s.empty?
      next unless numeric?(price)
      next unless numeric?(quantity)

      @inventory << {
        name: name,
        price: price.to_f,
        quantity: quantity.to_i
      }
    end
  end

  def insert_money(amount)
    return unless numeric?(amount)
    return unless amount.to_f > 0

    @balance = (@balance + amount.to_f).to_f
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def select_item(name)
    return "Item not found" if name.nil? || name.to_s.empty?

    item = @inventory.find { |i| i[:name] == name }

    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity].to_i <= 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price].to_f

    @balance = (@balance - item[:price].to_f).to_f
    item[:quantity] = item[:quantity].to_i - 1

    "Dispensed #{name}"
  end

  def check_stock(name)
    return 0 if name.nil?

    item = @inventory.find { |i| i[:name] == name }
    item ? item[:quantity].to_i : 0
  end

  def restock(name, quantity)
    return if name.nil? || name.to_s.empty?
    return unless numeric?(quantity)
    return unless quantity.to_i > 0

    item = @inventory.find { |i| i[:name] == name }

    if item
      item[:quantity] = item[:quantity].to_i + quantity.to_i
    else
      @inventory << {
        name: name,
        price: 1.25,
        quantity: quantity.to_i
      }
    end
  end

  def get_available_items
    @inventory.select { |item| item[:quantity].to_i > 0 }
  end

  private

  def numeric?(value)
    value.is_a?(Numeric) && value.finite?
  end
end