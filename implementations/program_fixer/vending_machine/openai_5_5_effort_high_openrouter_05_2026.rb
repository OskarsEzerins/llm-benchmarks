class VendingMachine
  attr_reader :balance, :inventory

  DEFAULT_RESTOCK_PRICE = 1.25

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
    amount = finite_float(amount)
    return nil unless amount && amount > 0

    @balance += amount
  end

  def select_item(name)
    return "Item not found" if blank_name?(name)

    item = find_item(name)
    return "Item not found" if item.nil?

    quantity = item_quantity(item)
    return "Item out of stock" if quantity <= 0

    price = finite_float(item[:price])
    return "Item not found" unless price

    return "Insufficient funds. Please insert more money." if @balance < price

    @balance -= price
    item[:quantity] = quantity - 1

    "Dispensed #{name}"
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def check_stock(name)
    return 0 if blank_name?(name)

    item = find_item(name)
    item ? item_quantity(item) : 0
  end

  def restock(name, quantity)
    return nil if blank_name?(name)

    quantity = integer_quantity(quantity)
    return nil unless quantity && quantity > 0

    item = find_item(name)

    if item
      item[:quantity] = item_quantity(item) + quantity
    else
      @inventory << { name: name, price: DEFAULT_RESTOCK_PRICE, quantity: quantity }
    end
  end

  def get_available_items
    @inventory.select { |item| item_quantity(item) > 0 }
  end

  private

  def find_item(name)
    @inventory.find { |item| item[:name] == name }
  end

  def normalize_item(item)
    return nil unless item.is_a?(Hash)

    name = hash_value(item, :name)
    return nil if blank_name?(name)

    price = finite_float(hash_value(item, :price))
    return nil unless price && price >= 0

    quantity = integer_quantity(hash_value(item, :quantity)) || 0
    quantity = 0 if quantity < 0

    { name: name, price: price, quantity: quantity }
  end

  def hash_value(hash, key)
    hash.key?(key) ? hash[key] : hash[key.to_s]
  end

  def blank_name?(name)
    name.nil? || (name.is_a?(String) && name.strip.empty?) || (name.respond_to?(:empty?) && name.empty?)
  end

  def finite_float(value)
    return nil unless value.is_a?(Numeric)

    float = value.to_f
    float.finite? ? float : nil
  rescue
    nil
  end

  def integer_quantity(value)
    return nil unless value.is_a?(Numeric)

    value.to_i
  rescue
    nil
  end

  def item_quantity(item)
    quantity = integer_quantity(item[:quantity]) || 0
    quantity < 0 ? 0 : quantity
  end
end