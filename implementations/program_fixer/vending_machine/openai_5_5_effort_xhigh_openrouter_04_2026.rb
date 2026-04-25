class VendingMachine
  attr_reader :balance, :inventory

  DEFAULT_RESTOCK_PRICE = 1.25

  def initialize(items = nil)
    @inventory = []
    @balance = 0.0

    return unless items.is_a?(Array)

    items.each do |item|
      normalized_item = normalize_item(item)
      @inventory << normalized_item if normalized_item
    end
  end

  def insert_money(amount)
    return unless positive_number?(amount)

    @balance = (@balance + amount.to_f).to_f
  end

  def select_item(name)
    return "Item not found" if invalid_name?(name)

    item = find_item(name)

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

    item = find_item(name)
    item ? item[:quantity].to_i : 0
  end

  def restock(name, quantity)
    return if invalid_name?(name)
    return unless valid_quantity?(quantity, allow_zero: false)

    amount = quantity.to_i
    item = find_item(name)

    if item
      item[:quantity] = item[:quantity].to_i + amount
    else
      @inventory << { name: name, price: DEFAULT_RESTOCK_PRICE, quantity: amount }
    end
  end

  def get_available_items
    @inventory.select { |item| item.is_a?(Hash) && item[:quantity].to_i > 0 }
  end

  private

  def find_item(name)
    @inventory.find { |item| item.is_a?(Hash) && item[:name] == name }
  end

  def normalize_item(item)
    return nil unless item.is_a?(Hash)

    name = fetch_hash_value(item, :name)
    price = fetch_hash_value(item, :price)
    quantity = fetch_hash_value(item, :quantity)

    return nil if invalid_name?(name)
    return nil unless valid_number?(price) && price.to_f >= 0.0
    return nil unless valid_quantity?(quantity, allow_zero: true)

    { name: name, price: price.to_f, quantity: quantity.to_i }
  end

  def fetch_hash_value(hash, key)
    hash.key?(key) ? hash[key] : hash[key.to_s]
  end

  def invalid_name?(name)
    name.nil? || (name.respond_to?(:strip) ? name.strip.empty? : name.respond_to?(:empty?) && name.empty?)
  end

  def valid_number?(value)
    return false unless value.is_a?(Numeric)
    return false if defined?(Complex) && value.is_a?(Complex)

    value.to_f.finite?
  rescue StandardError
    false
  end

  def positive_number?(value)
    valid_number?(value) && value.to_f > 0.0
  end

  def valid_quantity?(value, allow_zero:)
    return false unless valid_number?(value)

    integer_value = value.to_i
    return false unless value == integer_value

    allow_zero ? integer_value >= 0 : integer_value > 0
  rescue StandardError
    false
  end
end