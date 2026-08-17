class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = build_inventory(items)
    @balance = 0.0
  end

  def insert_money(amount)
    return unless valid_money?(amount)

    @balance = normalize_balance(@balance + amount.to_f)
  end

  def return_change
    change = @balance.to_f
    @balance = 0.0
    change
  end

  def select_item(name)
    return "Item not found" if invalid_name?(name)

    item = find_item(name)
    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity].to_i <= 0

    price = item[:price].to_f
    return "Insufficient funds. Please insert more money." if @balance < price

    @balance = normalize_balance(@balance - price)
    item[:quantity] = item[:quantity].to_i - 1
    "Dispensed #{name}"
  end

  def check_stock(name)
    return 0 if invalid_name?(name)

    item = find_item(name)
    item ? item[:quantity].to_i : 0
  end

  def restock(name, quantity)
    return if invalid_name?(name)
    return unless valid_quantity?(quantity)

    qty = quantity.to_i
    item = find_item(name)

    if item
      item[:quantity] = item[:quantity].to_i + qty
    else
      @inventory << { name: name, price: 1.25, quantity: qty }
      qty
    end
  end

  def get_available_items
    @inventory.select { |item| item[:quantity].to_i > 0 }.map { |item| item.dup }
  end

  private

  def build_inventory(items)
    raw_items =
      begin
        if items.is_a?(Array)
          items
        elsif items.is_a?(Hash)
          [items]
        elsif items.respond_to?(:to_ary)
          Array(items)
        else
          []
        end
      rescue StandardError
        []
      end

    raw_items.each_with_object([]) do |item, inventory|
      next unless item.is_a?(Hash)

      name = item[:name]
      name = item["name"] if name.nil?
      next if invalid_name?(name)

      price = item[:price]
      price = item["price"] if price.nil?
      next unless valid_price?(price)

      quantity = item[:quantity]
      quantity = item["quantity"] if quantity.nil?
      quantity = quantity.is_a?(Numeric) && finite_number?(quantity) ? quantity.to_i : 0
      quantity = 0 if quantity < 0

      inventory << { name: name, price: price.to_f.round(12), quantity: quantity }
    end
  end

  def find_item(name)
    @inventory.find { |item| item[:name] == name || item[:name].to_s == name.to_s }
  end

  def invalid_name?(name)
    return true if name.nil?
    return true if name.respond_to?(:empty?) && name.empty?

    false
  rescue StandardError
    true
  end

  def valid_money?(amount)
    amount.is_a?(Numeric) && amount > 0 && finite_number?(amount)
  rescue StandardError
    false
  end

  def valid_price?(price)
    price.is_a?(Numeric) && price >= 0 && finite_number?(price)
  rescue StandardError
    false
  end

  def valid_quantity?(quantity)
    return false unless quantity.is_a?(Numeric) && quantity > 0 && finite_number?(quantity)

    quantity_as_int = quantity.to_i
    quantity_as_int > 0 && quantity_as_int == quantity.to_f
  rescue StandardError
    false
  end

  def finite_number?(value)
    return true unless value.respond_to?(:finite?)

    value.finite?
  rescue StandardError
    false
  end

  def normalize_balance(value)
    result = value.to_f.round(12)
    result.zero? ? 0.0 : result
  end
end