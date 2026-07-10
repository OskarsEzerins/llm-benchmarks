class VendingMachine
  attr_reader :inventory, :balance

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

  def select_item(name)
    return "Item not found" if invalid_name?(name)

    item = @inventory.find { |i| i[:name] == name }

    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity].to_i <= 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price].to_f

    @balance = (@balance - item[:price].to_f).to_f
    item[:quantity] = item[:quantity].to_i - 1

    "Dispensed #{name}"
  end

  def return_change
    change = @balance.to_f
    @balance = 0.0
    change
  end

  def check_stock(name)
    return 0 if invalid_name?(name)

    item = @inventory.find { |i| i[:name] == name }
    item ? item[:quantity].to_i : 0
  end

  def restock(name, quantity)
    return nil if invalid_name?(name)

    qty = positive_integer_quantity(quantity)
    return nil if qty.nil?

    item = @inventory.find { |i| i[:name] == name }

    if item
      item[:quantity] = item[:quantity].to_i + qty
    else
      item = { name: name, price: 1.25, quantity: qty }
      @inventory << item
    end

    item
  end

  def get_available_items
    @inventory.select { |item| item[:quantity].to_i > 0 }
  end

  private

  def normalize_item(item)
    return nil unless item.is_a?(Hash)

    name = hash_value(item, :name)
    return nil if invalid_name?(name)

    price = numeric_to_float(hash_value(item, :price))
    price = 0.0 if price.nil? || price.negative?

    quantity = non_negative_integer_quantity(hash_value(item, :quantity)) || 0

    {
      name: name,
      price: price.to_f,
      quantity: quantity.to_i
    }
  end

  def hash_value(hash, key)
    if hash.key?(key)
      hash[key]
    elsif hash.key?(key.to_s)
      hash[key.to_s]
    end
  end

  def invalid_name?(name)
    name.nil? || (name.respond_to?(:empty?) && name.empty?)
  end

  def positive_number?(value)
    number = numeric_to_float(value)
    !number.nil? && number > 0
  end

  def numeric_to_float(value)
    return nil unless value.is_a?(Numeric)

    number = value.to_f
    return nil unless number.finite?

    number
  rescue
    nil
  end

  def non_negative_integer_quantity(value)
    return nil unless value.is_a?(Numeric)

    number = value.to_f
    return nil unless number.finite?
    return nil if number < 0
    return nil unless number == number.to_i

    number.to_i
  rescue
    nil
  end

  def positive_integer_quantity(value)
    quantity = non_negative_integer_quantity(value)
    return nil if quantity.nil? || quantity <= 0

    quantity
  end
end