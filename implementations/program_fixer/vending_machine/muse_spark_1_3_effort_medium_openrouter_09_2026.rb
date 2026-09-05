class VendingMachine
  attr_reader :balance
  attr_reader :inventory

  def initialize(items = nil)
    @balance = 0.0
    if items.is_a?(Array)
      @inventory = items.select { |i| i.is_a?(Hash) }.map do |i|
        name = i[:name] || i['name'] || i[:title] || i['title']
        price_val = i.key?(:price) ? i[:price] : (i.key?('price') ? i['price'] : 1.25)
        qty_val = if i.key?(:quantity)
                    i[:quantity]
                  elsif i.key?('quantity')
                    i['quantity']
                  elsif i.key?(:qty)
                    i[:qty]
                  elsif i.key?('qty')
                    i['qty']
                  else
                    0
                  end
        begin
          price = Float(price_val)
        rescue
          price = 1.25
        end
        quantity = begin
          Integer(qty_val)
        rescue
          begin
            qty_val.to_i
          rescue
            0
          end
        end
        { name: name, price: price.to_f, quantity: quantity.to_i }
      end
    else
      @inventory = []
    end
  end

  def insert_money(amount)
    return unless amount.is_a?(Numeric)
    return unless amount > 0
    return if amount.is_a?(Float) && !amount.finite?
    @balance = (@balance + amount.to_f).to_f
  end

  def select_item(label)
    return "Item not found" if label.nil?
    return "Item not found" if label.respond_to?(:empty?) && label.empty?
    item = @inventory.find { |i| (i[:name] || i['name']) == label }
    return "Item not found" if item.nil?
    qty = item[:quantity] || item['quantity'] || 0
    return "Item out of stock" if qty.to_i <= 0
    price = (item[:price] || item['price'] || 0).to_f
    return "Insufficient funds. Please insert more money." if @balance < price
    @balance = (@balance - price).to_f
    if item.key?(:quantity)
      item[:quantity] = item[:quantity].to_i - 1
    else
      item['quantity'] = item['quantity'].to_i - 1
      item[:quantity] = item['quantity']
    end
    "Dispensed #{item[:name] || item['name']}"
  end

  def return_change
    change = @balance.to_f
    @balance = 0.0
    change
  end

  def check_stock(label)
    return 0 if label.nil?
    return 0 if label.respond_to?(:empty?) && label.empty?
    thing = @inventory.find { |i| (i[:name] || i['name']) == label }
    return 0 if thing.nil?
    qty = thing[:quantity].nil? ? thing['quantity'] : thing[:quantity]
    return 0 if qty.nil?
    qty.to_i
  end

  def restock(label, qty)
    return if label.nil?
    return if label.respond_to?(:empty?) && label.empty?
    return unless qty.is_a?(Numeric)
    return unless qty > 0
    return if qty.is_a?(Float) && !qty.finite?
    int_qty = qty.to_i
    return unless int_qty > 0
    stock = @inventory.find { |i| (i[:name] || i['name']) == label }
    if stock
      if stock.key?(:quantity)
        stock[:quantity] = stock[:quantity].to_i + int_qty
      else
        stock['quantity'] = stock['quantity'].to_i + int_qty
        stock[:quantity] = stock['quantity']
      end
    else
      @inventory << { name: label, price: 1.25, quantity: int_qty }
    end
  end

  def get_available_items
    @inventory.select do |i|
      q = i[:quantity].nil? ? i['quantity'] : i[:quantity]
      q.to_i > 0
    end
  end
end