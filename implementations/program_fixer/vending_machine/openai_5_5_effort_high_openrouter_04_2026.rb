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
    return @balance unless positive_numeric?(amount)

    @balance = (@balance + amount.to_f).to_f
  end

  def return_change
    change = @balance.to_f
    @balance = 0.0
    change
  end

  def select_item(name)
    return "Item not found" if blank_name?(name)

    item = find_item(name)

    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity].to_i <= 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price].to_f

    @balance = (@balance - item[:price].to_f).to_f
    item[:quantity] = item[:quantity].to_i - 1

    "Dispensed #{name}"
  end

  def check_stock(name)
    return 0 if blank_name?(name)

    item = find_item(name)
    item ? item[:quantity].to_i : 0
  end

  def restock(name, quantity)
    return nil if blank_name?(name)
    return nil unless positive_numeric?(quantity)

    quantity = quantity.to_i
    return nil if quantity <= 0

    item = find_item(name)

    if item
      item[:quantity] = item[:quantity].to_i + quantity
    else
      item = { name: name, price: DEFAULT_RESTOCK_PRICE.to_f, quantity: quantity }
      @inventory << item
    end

    item
  end

  def get_available_items
    @inventory.select { |item| item[:quantity].to_i > 0 }
  end

  private

  def find_item(name)
    @inventory.find { |item| item[:name] == name }
  end

  def normalize_item(item)
    return nil unless item.is_a?(Hash)

    name = fetch_key(item, :name)
    price = fetch_key(item, :price)
    quantity = fetch_key(item, :quantity)

    return nil if blank_name?(name)
    return nil unless non_negative_numeric?(price)

    quantity = non_negative_numeric?(quantity) ? quantity.to_i : 0

    {
      name: name,
      price: price.to_f,
      quantity: quantity
    }
  end

  def fetch_key(hash, key)
    hash.key?(key) ? hash[key] : hash[key.to_s]
  end

  def blank_name?(name)
    name.nil? || (name.respond_to?(:empty?) && name.empty?)
  end

  def positive_numeric?(value)
    value.is_a?(Numeric) && value > 0
  rescue StandardError
    false
  end

  def non_negative_numeric?(value)
    value.is_a?(Numeric) && value >= 0
  rescue StandardError
    false
  end
end