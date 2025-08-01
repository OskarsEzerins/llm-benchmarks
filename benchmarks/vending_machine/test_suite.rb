# frozen_string_literal: true

# Handle minitest loading for both standalone and subprocess execution
begin
  require 'minitest/autorun'
rescue LoadError
  begin
    require 'minitest'
  rescue LoadError
    # If minitest still not available, define minimal test framework
    module Minitest
      class Test
        def initialize(name)
          @name = name
        end

        def setup; end

        module Assertions
          class Assertion < StandardError; end

          def assert(test, msg = 'Failed assertion, no message given.')
            raise Assertion, msg unless test
          end

          def assert_equal(expected, actual, msg = nil)
            return if expected == actual

            raise Assertion, msg || "Expected #{expected.inspect}, got #{actual.inspect}"
          end

          def assert_in_delta(expected, actual, delta = 0.001, msg = nil)
            return if (expected - actual).abs <= delta

            raise Assertion, msg || "Expected #{expected} to be within #{delta} of #{actual}"
          end

          def assert_raises(exception_class)
            yield
            raise Assertion, "Expected #{exception_class} to be raised"
          rescue exception_class
            # Expected exception was raised
          end
        end

        include Assertions
      end
    end
  end
end

class VendingMachineTest < Minitest::Test
  def setup
    items = [
      { name: 'Cola', price: 1.50, quantity: 5 },
      { name: 'Chips', price: 1.00, quantity: 10 },
      { name: 'Candy', price: 0.75, quantity: 0 }
    ]
    @vending_machine = VendingMachine.new(items)
  end

  def test_initialization
    assert_equal 0.0, @vending_machine.balance
    assert_equal 3, @vending_machine.items.size
  end

  def test_insert_money_valid
    @vending_machine.insert_money(1.0)
    assert_equal 1.0, @vending_machine.balance
    @vending_machine.insert_money(0.5)
    assert_equal 1.5, @vending_machine.balance
  end

  def test_insert_money_invalid
    @vending_machine.insert_money(-0.5)
    assert_equal 0.0, @vending_machine.balance
  end

  def test_select_item_success
    @vending_machine.insert_money(2.0)
    message = @vending_machine.select_item('Cola')
    assert_equal 'Dispensed Cola', message
    assert_in_delta 0.50, @vending_machine.balance
    assert_equal 4, @vending_machine.items.find { |i| i[:name] == 'Cola' }[:quantity]
  end

  def test_select_item_insufficient_funds
    @vending_machine.insert_money(1.0)
    message = @vending_machine.select_item('Cola')
    assert_equal 'Insufficient funds. Please insert more money.', message
    assert_equal 1.0, @vending_machine.balance
    assert_equal 5, @vending_machine.items.find { |i| i[:name] == 'Cola' }[:quantity]
  end

  def test_select_item_out_of_stock
    @vending_machine.insert_money(1.0)
    message = @vending_machine.select_item('Candy')
    assert_equal 'Item out of stock', message
    assert_equal 1.0, @vending_machine.balance
  end

  def test_select_item_not_found
    @vending_machine.insert_money(1.0)
    message = @vending_machine.select_item('Water')
    assert_equal 'Item not found', message
  end

  def test_return_change
    @vending_machine.insert_money(1.25)
    change = @vending_machine.return_change
    assert_in_delta 1.25, change
    assert_equal 0.0, @vending_machine.balance
  end

  def test_check_stock
    assert_equal 5, @vending_machine.check_stock('Cola')
    assert_equal 10, @vending_machine.check_stock('Chips')
    assert_equal 0, @vending_machine.check_stock('Candy')
    assert_equal 0, @vending_machine.check_stock('Water')
  end

  def test_restock_existing_item
    @vending_machine.restock('Cola', 10)
    assert_equal 15, @vending_machine.check_stock('Cola')
  end

  def test_restock_new_item
    @vending_machine.restock('Gum', 20)
    assert_equal 20, @vending_machine.check_stock('Gum')
    new_item = @vending_machine.items.find { |i| i[:name] == 'Gum' }
    assert new_item, 'New item should be added'
    assert_equal 1.25, new_item[:price] # Assuming a default price for new items
  end

  def test_get_available_items
    # This test assumes the fixed code will have a `get_available_items` method
    available = @vending_machine.get_available_items
    assert_equal 2, available.size
    assert_equal 'Cola', available[0][:name]
    assert_equal 'Chips', available[1][:name]
  end

  def test_insert_money_zero
    @vending_machine.insert_money(0)
    assert_equal 0.0, @vending_machine.balance
  end

  def test_insert_money_nil
    # Should handle nil gracefully
    @vending_machine.insert_money(nil)
    assert_equal 0.0, @vending_machine.balance
  end

  def test_insert_money_string
    # Should handle non-numeric input gracefully
    @vending_machine.insert_money("invalid")
    assert_equal 0.0, @vending_machine.balance
  end

  def test_select_item_nil_name
    @vending_machine.insert_money(2.0)
    message = @vending_machine.select_item(nil)
    assert_equal 'Item not found', message
  end

  def test_select_item_empty_string
    @vending_machine.insert_money(2.0)
    message = @vending_machine.select_item("")
    assert_equal 'Item not found', message
  end

  def test_check_stock_nil_name
    stock = @vending_machine.check_stock(nil)
    assert_equal 0, stock
  end

  def test_check_stock_empty_string
    stock = @vending_machine.check_stock("")
    assert_equal 0, stock
  end

  def test_restock_negative_quantity
    # Should handle negative quantities appropriately
    original_stock = @vending_machine.check_stock('Cola')
    @vending_machine.restock('Cola', -5)
    # Stock should not become negative
    assert @vending_machine.check_stock('Cola') >= 0
  end

  def test_restock_zero_quantity
    original_stock = @vending_machine.check_stock('Cola')
    @vending_machine.restock('Cola', 0)
    assert_equal original_stock, @vending_machine.check_stock('Cola')
  end

  def test_restock_nil_parameters
    # Should handle nil parameters gracefully
    @vending_machine.restock(nil, 5)
    @vending_machine.restock('Cola', nil)
    # Should not crash and items should remain unchanged for invalid parameters
  end

  def test_initialization_with_nil
    # Should handle nil items array
    machine = VendingMachine.new(nil)
    assert_equal 0.0, machine.balance
    assert machine.items.is_a?(Array)
  end

  def test_initialization_with_invalid_items
    # Should handle malformed item data
    items = [
      { name: nil, price: 1.50, quantity: 5 },
      { name: 'Soda', price: "invalid", quantity: 3 },
      { name: 'Candy', price: 0.75, quantity: nil }
    ]
    machine = VendingMachine.new(items)
    assert_equal 0.0, machine.balance
  end

  def test_select_item_exact_change
    @vending_machine.insert_money(1.50)
    message = @vending_machine.select_item('Cola')
    assert_equal 'Dispensed Cola', message
    assert_equal 0.0, @vending_machine.balance
  end

  def test_multiple_select_same_item_until_empty
    @vending_machine.insert_money(10.0)

    # Buy all Cola items (5 total)
    5.times do
      message = @vending_machine.select_item('Cola')
      assert_equal 'Dispensed Cola', message
    end

    # Try to buy one more - should be out of stock
    message = @vending_machine.select_item('Cola')
    assert_equal 'Item out of stock', message
    assert_equal 0, @vending_machine.check_stock('Cola')
  end

  def test_return_change_when_zero
    change = @vending_machine.return_change
    assert_equal 0.0, change
    assert_equal 0.0, @vending_machine.balance
  end

  def test_balance_type_consistency
    # Balance should always be a Float
    assert @vending_machine.balance.is_a?(Float)
    @vending_machine.insert_money(1.5)
    assert @vending_machine.balance.is_a?(Float)
  end

  def test_items_array_not_modified_during_operations
    original_items_count = @vending_machine.items.size
    @vending_machine.insert_money(2.0)
    @vending_machine.select_item('Cola')
    @vending_machine.return_change
    assert_equal original_items_count, @vending_machine.items.size
  end

  def test_case_sensitivity_item_names
    @vending_machine.insert_money(2.0)
    message = @vending_machine.select_item('cola') # lowercase
    assert_equal 'Item not found', message
    message = @vending_machine.select_item('COLA') # uppercase
    assert_equal 'Item not found', message
  end

  def test_full_transaction
    @vending_machine.insert_money(1.0)
    @vending_machine.insert_money(1.0) # balance = 2.0
    @vending_machine.select_item('Cola') # price 1.5, balance = 0.5
    @vending_machine.select_item('Chips') # price 1.0, insufficient funds
    assert_equal 'Insufficient funds. Please insert more money.', @vending_machine.select_item('Chips')
    @vending_machine.insert_money(0.5) # balance = 1.0
    @vending_machine.select_item('Chips') # price 1.0, balance = 0.0
    assert_equal 'Dispensed Chips', @vending_machine.select_item('Chips')
    assert_equal 0.0, @vending_machine.balance
    assert_equal 9, @vending_machine.check_stock('Chips')
    change = @vending_machine.return_change
    assert_equal 0.0, change
  end
end
