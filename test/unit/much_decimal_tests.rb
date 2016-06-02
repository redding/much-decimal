require 'assert'
require 'much-decimal'

module MuchDecimal

  class UnitTests < Assert::Context
    desc "MuchDecimal"
    setup do
      @module = MuchDecimal
    end
    subject{ @module }

    should have_imeths :integer_to_decimal, :decimal_to_integer

    should "use much-plugin" do
      assert_includes MuchPlugin, subject
    end

    should "know its default precision" do
      assert_equal 2, DEFAULT_PRECISION
    end

    should "know how to convert an integer to a decimal" do
      integer          = Factory.integer
      precision        = Factory.integer(10)
      base_10_modifier = (10.0 ** precision)

      exp = integer / base_10_modifier
      assert_equal exp, subject.integer_to_decimal(integer,      precision)
      assert_equal exp, subject.integer_to_decimal(integer.to_s, precision)

      invalid_value = [nil, '', true, false].sample
      assert_nil subject.integer_to_decimal(invalid_value, precision)
    end

    should "know how to convert a decimal to an integer" do
      decimal          = Factory.float
      precision        = Factory.integer(10)
      base_10_modifier = (10.0 ** precision)

      exp = (decimal * base_10_modifier).round.to_i
      assert_equal exp, subject.decimal_to_integer(decimal,      precision)
      assert_equal exp, subject.decimal_to_integer(decimal.to_s, precision)

      invalid_value = [nil, '', true, false].sample
      assert_nil subject.decimal_to_integer(invalid_value, precision)
    end

  end

  class MixinTests < UnitTests
    desc "when mixed in"
    setup do
      @class = Class.new do
        include MuchDecimal
        attr_accessor :seconds_as_integer, :integer_seconds
      end
    end
    subject{ @class }

    should have_imeths :decimal_as_integer

    should "add a decimal-as-integer accessor using `decimal_as_integer`" do
      subject.decimal_as_integer :seconds

      instance = subject.new
      assert_respond_to :seconds,  instance
      assert_respond_to :seconds=, instance

      decimal = Factory.float
      integer = Factory.integer

      instance.seconds = decimal
      exp = @module.decimal_to_integer(decimal, DEFAULT_PRECISION)
      assert_equal exp, instance.seconds_as_integer

      instance.seconds_as_integer = integer
      exp = @module.integer_to_decimal(integer, DEFAULT_PRECISION)
      assert_equal exp, instance.seconds
    end

    should "allow specifying custom options using `decimal_as_integer`" do
      source    = :integer_seconds
      precision = Factory.integer(5)
      subject.decimal_as_integer :seconds, {
        :source    => source,
        :precision => precision
      }

      instance = subject.new
      assert_respond_to :seconds,  instance
      assert_respond_to :seconds=, instance

      decimal = Factory.float
      integer = Factory.integer

      instance.seconds = decimal
      exp = @module.decimal_to_integer(decimal, precision)
      assert_equal exp, instance.send(source)

      instance.send("#{source}=", integer)
      exp = @module.integer_to_decimal(integer, precision)
      assert_equal exp, instance.seconds
    end

  end

  class EdgeCaseTests < UnitTests
    desc "edge cases"
    setup do
      @class = Class.new do
        include MuchDecimal

        attr_accessor :ten_thousandth_seconds

        decimal_as_integer(:seconds, {
          :source    => :ten_thousandth_seconds,
          :precision => 4
        })
      end
      @instance = @class.new
    end
    subject{ @instance }

    should "allow writing and reading `nil` values" do
      assert_nil subject.ten_thousandth_seconds
      assert_nil subject.seconds

      subject.seconds = 1.2345
      assert_equal 12345,  subject.ten_thousandth_seconds
      assert_equal 1.2345, subject.seconds

      assert_nothing_raised{ subject.seconds = nil }
      assert_nil subject.seconds
      assert_nil subject.ten_thousandth_seconds
    end

    should "write empty string values as `nil` values" do
      subject.seconds = 1.2345
      assert_not_nil subject.ten_thousandth_seconds
      assert_not_nil subject.seconds

      assert_nothing_raised{ subject.seconds = '' }
      assert_nil subject.seconds
      assert_nil subject.ten_thousandth_seconds
    end

    should "write values that can't be converted as `nil` values" do
      subject.seconds = 1.2345
      assert_not_nil subject.ten_thousandth_seconds
      assert_not_nil subject.seconds

      assert_nothing_raised{ subject.seconds = true }
      assert_nil subject.seconds
      assert_nil subject.ten_thousandth_seconds
    end

    should "handle decimals with less significant digits" do
      subject.seconds = 1.12
      assert_equal 11200, subject.ten_thousandth_seconds
      assert_equal 1.12,  subject.seconds
    end

    should "handle integers" do
      subject.seconds = 5
      assert_equal 50000, subject.ten_thousandth_seconds
      assert_equal 5.0,   subject.seconds
    end

    should "handle decimals that are less than 1" do
      subject.seconds = 0.0001
      assert_equal 1,      subject.ten_thousandth_seconds
      assert_equal 0.0001, subject.seconds
    end

    should "handle decimals with too many significant digits by rounding" do
      subject.seconds = 1.00005
      assert_equal 10001,  subject.ten_thousandth_seconds
      assert_equal 1.0001, subject.seconds
    end

    should "handle repeating decimals" do
      subject.seconds = 1 / 3.0
      assert_equal 3333,   subject.ten_thousandth_seconds
      assert_equal 0.3333, subject.seconds
    end

  end

end
