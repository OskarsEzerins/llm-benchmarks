class VendingMachine
  def initialize(items = nil)
    @inventory = []
    (items || []).each do |item|
      if item.is_a?(Hash) && item[:name].is_a?(String) && item[:price].is_a?(Numeric) && item[:quantity].is_a?(Integer) && item[:quantity] >= 0
        @inventory << { name: item[:name], price: item[:price].to_f, quantity: item[:quantity] }
      end
    end
    @balance = 0.0
  end

  def balance
    @balance
  end

  def insert_money(amount)
    if amount.is_a?(Numeric) && amount > 0
      @balance += amount.to_f
    end
  end

  def return_change
    change = @balance
    @balance = 0.0
    change
  end

  def select_item(name)
    return "Item not found" unless name.is_a?(String) && !name.strip.empty?

    item = @inventory.find { |i| i[:name] == name }

    return "Item not found" if item.nil?
    return "Item out of stock" if item[:quantity] == 0
    return "Insufficient funds. Please insert more money." if @balance < item[:price]

    @balance -= item[:price]
    item[:quantity] -= 1
    "Dispensed #{name}"
  end

  def check_stock(name)
    return 0 unless name.is_a?(String) && !name.strip.empty?

    item = @inventory.find { |i| i[:name] == name }
    item ? item[:quantity] : 0
  end

  def restock(name, quantity)
    return unless name.is_a?(String) && !name.strip.empty?
    return unless quantity.is_a?(Integer) && quantity > 0

    item = @inventory.find { |i| i[:name] == name }
    if item
      item[:quantity] += quantity
    else
      @inventory << { name: name, price: 1.25, quantity: quantity }
    end
  end

  def get_available_items
    @inventory.select { |item| item[:quantity] > 0 }
  end
end