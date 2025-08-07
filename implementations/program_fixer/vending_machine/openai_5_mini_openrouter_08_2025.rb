class VendingMachine
  attr_reader :balance

  def initialize(items = nil)
    @inventory = []
    if items.is_a?(Array)
      items.each do |it|
        next unless it.is_a?(Hash)
        name = it[:name] || it['name']
        price = it[:price] || it['price']
        qty = it[:quantity] || it['quantity']

        next if name.nil?
        name_s = name.to_s.strip
        next if name_s.empty?

        # Ensure numeric types
        begin
          price_f = Float(price)
        rescue
          next
        end

        begin
          qty_i = Integer(qty)
        rescue
          next
        end

        @inventory << { name: name_s, price: price_f.to_f, quantity: qty_i.to_i }
      end
    end
    @balance = 0.0
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric)
    return unless amount > 0
    @balance += amount.to_f
  end

  def select_item(name)
    return 'Item not found' if name.nil?
    name_s = name.to_s
    return 'Item not found' if name_s.strip.empty?

    item = @inventory.find { |i| i[:name] == name_s }
    return 'Item not found' if item.nil?

    return 'Item out of stock' if item[:quantity].to_i <= 0

    return 'Insufficient funds. Please insert more money.' if @balance < item[:price].to_f

    # Successful purchase
    item[:quantity] = item[:quantity].to_i - 1
    @balance = (@balance - item[:price].to_f).to_f
    "Dispensed #{name_s}"
  end

  def return_change
    change = @balance.to_f
    @balance = 0.0
    change
  end

  def check_stock(name)
    return 0 if name.nil?
    name_s = name.to_s
    return 0 if name_s.strip.empty?

    item = @inventory.find { |i| i[:name] == name_s }
    item ? item[:quantity].to_i : 0
  end

  def restock(name, qty)
    return false if name.nil?
    name_s = name.to_s.strip
    return false if name_s.empty?

    begin
      qty_i = Integer(qty)
    rescue
      return false
    end
    return false if qty_i <= 0

    item = @inventory.find { |i| i[:name] == name_s }
    if item
      item[:quantity] = item[:quantity].to_i + qty_i
    else
      @inventory << { name: name_s, price: 1.25, quantity: qty_i }
    end
    true
  end

  def get_available_items
    @inventory.select { |i| i[:quantity].to_i > 0 }
  end
end