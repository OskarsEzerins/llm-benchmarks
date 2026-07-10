class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @balance = 0.0
    @inventory = []

    if items.is_a?(Array)
      items.each do |item|
        normalized_item = normalize_item(item)
        @inventory << normalized_item if normalized_item
      end
    end
  end

  def insert_money(amount)
    value = finite_float(amount)
    return unless value && value > 0

    @balance = (@balance + value).to_f
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def select_item(name)
    return "Item not found" unless valid_name?(name)

    item = @inventory.find { |entry| entry[:name] == name }

    return "Item not found" unless item
    return "Item out of stock" if item[:quantity] <= 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price]

    @balance = (@balance - item[:price]).to_f
    item[:quantity] -= 1

    "Dispensed #{name}"
  end

  def check_stock(name)
    return 0 unless valid_name?(name)

    item = @inventory.find { |entry| entry[:name] == name }
    item ? item[:quantity] : 0
  end

  def restock(name, quantity)
    return unless valid_name?(name)

    amount = integer_quantity(quantity)
    return unless amount && amount > 0

    item = @inventory.find { |entry| entry[:name] == name }

    if item
      item[:quantity] += amount
    else
      @inventory << {
        name: name,
        price: 1.25,
        quantity: amount
      }
    end
  end

  def get_available_items
    @inventory.select { |item| item[:quantity] > 0 }
  end

  private

  def valid_name?(name)
    return false if name.nil?

    name.respond_to?(:empty?) ? !name.empty? : true
  end

  def finite_float(value)
    return nil unless value.is_a?(Numeric)

    converted = value.to_f
    converted.finite? ? converted : nil
  rescue StandardError
    nil
  end

  def integer_quantity(value)
    converted = finite_float(value)
    return nil unless converted
    return nil unless converted >= 0 && converted.floor == converted

    converted.to_i
  end

  def normalize_item(item)
    return unless item.is_a?(Hash)
    return unless valid_name?(item[:name])

    price = finite_float(item[:price])
    quantity = integer_quantity(item[:quantity])

    return unless price && price >= 0
    return unless quantity

    {
      name: item[:name],
      price: price,
      quantity: quantity
    }
  end
end