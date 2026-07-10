class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = []

    if items.is_a?(Array)
      items.each do |item|
        next unless item.is_a?(Hash)

        name = item[:name] || item["name"]
        price = item[:price] || item["price"]
        quantity = item[:quantity] || item["quantity"]

        next if name.nil? || name.to_s.empty?

        @inventory << {
          name: name,
          price: numeric?(price) ? price.to_f : 0.0,
          quantity: numeric?(quantity) ? quantity.to_i : 0
        }
      end
    end

    @balance = 0.0
  end

  def insert_money(amount)
    return unless numeric?(amount) && amount > 0

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
    return "Item out of stock" if item[:quantity] <= 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price]

    @balance = (@balance - item[:price]).to_f
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
    return unless numeric?(quantity) && quantity > 0

    quantity = quantity.to_i
    item = @inventory.find { |i| i[:name] == name }

    if item
      item[:quantity] = item[:quantity].to_i + quantity
    else
      @inventory << {
        name: name,
        price: 1.25,
        quantity: quantity
      }
    end
  end

  def get_available_items
    @inventory.select { |item| item[:quantity].to_i > 0 }
  end

  private

  def numeric?(value)
    value.is_a?(Numeric)
  end
end