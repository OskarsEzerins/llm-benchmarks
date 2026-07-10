class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = []

    if items.is_a?(Array)
      items.each do |item|
        normalized_item = normalize_item(item)
        @inventory << normalized_item if normalized_item
      end
    end

    @balance = 0.0
  end

  def insert_money(amount)
    return unless positive_number?(amount)

    @balance = (@balance + amount.to_f).to_f
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def select_item(name)
    return "Item not found" unless valid_name?(name)

    item = @inventory.find { |inventory_item| inventory_item[:name] == name }
    return "Item not found" unless item
    return "Item out of stock" if item[:quantity] <= 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price]

    @balance = (@balance - item[:price]).to_f
    item[:quantity] -= 1

    "Dispensed #{name}"
  end

  def check_stock(name)
    return 0 unless valid_name?(name)

    item = @inventory.find { |inventory_item| inventory_item[:name] == name }
    item ? item[:quantity] : 0
  end

  def restock(name, quantity)
    return unless valid_name?(name)

    quantity_to_add = normalize_quantity(quantity)
    return unless quantity_to_add && quantity_to_add > 0

    item = @inventory.find { |inventory_item| inventory_item[:name] == name }

    if item
      item[:quantity] += quantity_to_add
    else
      @inventory << {
        name: name,
        price: 1.25,
        quantity: quantity_to_add
      }
    end
  end

  def get_available_items
    @inventory.select { |item| item[:quantity] > 0 }.map(&:dup)
  end

  private

  def normalize_item(item)
    return unless item.is_a?(Hash)
    return unless valid_name?(item[:name])
    return unless valid_price?(item[:price])

    quantity = normalize_quantity(item[:quantity])
    return unless quantity

    {
      name: item[:name],
      price: item[:price].to_f,
      quantity: quantity
    }
  end

  def valid_name?(name)
    !name.nil? && (!name.respond_to?(:empty?) || !name.empty?)
  end

  def valid_price?(price)
    finite_numeric?(price) && price >= 0
  end

  def positive_number?(value)
    finite_numeric?(value) && value > 0
  end

  def normalize_quantity(value)
    return unless finite_numeric?(value)

    quantity = value.to_i
    return unless value == quantity
    return if quantity < 0

    quantity
  end

  def finite_numeric?(value)
    value.is_a?(Numeric) &&
      !value.is_a?(Complex) &&
      value.to_f.finite?
  rescue StandardError
    false
  end
end