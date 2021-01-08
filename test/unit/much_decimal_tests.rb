# frozen_string_literal: true

require "assert"
require "much-decimal"

module MuchDecimal
  class UnitTests < Assert::Context
    desc "MuchDecimal"
    subject { unit_module }

    let(:unit_module) { MuchDecimal }

    let(:integer) { Factory.integer }
    let(:decimal) { Factory.float }
    let(:precision) { Factory.integer(10) }
    let(:base_10_modifier) { 10.0 ** precision }
    let(:invalid_value) { [nil, '', true, false].sample }

    should have_imeths :integer_to_decimal, :decimal_to_integer

    should "use MuchMixin" do
      assert_that(subject).includes(MuchMixin)
    end

    should "know its default precision" do
      assert_that(DEFAULT_PRECISION).equals(2)
    end

    should "know how to convert an integer to a decimal" do
      exp = integer / base_10_modifier
      assert_that(subject.integer_to_decimal(integer, precision)).equals(exp)
      assert_that(subject.integer_to_decimal(integer.to_s, precision))
        .equals(exp)

      assert_that(subject.integer_to_decimal(invalid_value, precision)).is_nil
    end

    should "know how to convert a decimal to an integer" do
      exp = (decimal * base_10_modifier).round.to_i
      assert_that(subject.decimal_to_integer(decimal, precision)).equals(exp)
      assert_that(subject.decimal_to_integer(decimal.to_s, precision))
        .equals(exp)

      assert_that(subject.decimal_to_integer(invalid_value, precision)).is_nil
    end

  end

  class ReceiverSetupTests < UnitTests
    subject { receiver_class }

    let(:receiver_class) {
      Class.new do
        include MuchDecimal
        attr_accessor :seconds_as_integer, :integer_seconds
      end
    }
  end

  class ReceiverTests < ReceiverSetupTests
    desc "receiver"

    let(:decimal) { Factory.float }
    let(:integer) { Factory.integer }

    let(:custom_source) { :integer_seconds }
    let(:custom_precision) { Factory.integer(5) }

    should have_imeths :decimal_as_integer

    should "add a decimal-as-integer accessor using `decimal_as_integer`" do
      subject.decimal_as_integer(:seconds)

      receiver = subject.new
      assert_that(receiver).responds_to(:seconds)
      assert_that(receiver).responds_to(:seconds=)

      receiver.seconds = decimal
      assert_that(receiver.seconds_as_integer)
        .equals(unit_module.decimal_to_integer(decimal, DEFAULT_PRECISION))

      receiver.seconds_as_integer = integer
      assert_that(receiver.seconds)
        .equals(unit_module.integer_to_decimal(integer, DEFAULT_PRECISION))
    end

    should "allow specifying custom options using `decimal_as_integer`" do
      subject.decimal_as_integer(
        :seconds,
        source:    custom_source,
        precision: custom_precision
      )

      receiver = subject.new
      assert_that(receiver).responds_to(:seconds)
      assert_that(receiver).responds_to(:seconds=)

      receiver.seconds = decimal
      assert_that(receiver.public_send(custom_source))
        .equals(unit_module.decimal_to_integer(decimal, custom_precision))

      receiver.public_send("#{custom_source}=", integer)
      assert_that(receiver.seconds)
        .equals(unit_module.integer_to_decimal(integer, custom_precision))
    end

  end

  class EdgeCaseTests < UnitTests
    desc "edge cases"
    subject { receiver_class.new }

    let(:receiver_class) {
      Class.new do
        include MuchDecimal

        attr_accessor :ten_thousandth_seconds

        decimal_as_integer :seconds,
                           source:    :ten_thousandth_seconds,
                           precision: 4
      end
    }

    should "allow writing and reading `nil` values" do
      assert_that(subject.ten_thousandth_seconds).is_nil
      assert_that(subject.seconds).is_nil

      subject.seconds = 1.2345
      assert_that(subject.ten_thousandth_seconds).equals(12345)
      assert_that(subject.seconds).equals(1.2345)

      assert_that { subject.seconds = nil }.does_not_raise
      assert_that(subject.seconds).is_nil
      assert_that(subject.ten_thousandth_seconds).is_nil
    end

    should "write empty string values as `nil` values" do
      subject.seconds = 1.2345
      assert_that(subject.ten_thousandth_seconds).is_not_nil
      assert_that(subject.seconds).is_not_nil

      assert_that { subject.seconds = "" }.does_not_raise
      assert_that(subject.seconds).is_nil
      assert_that(subject.ten_thousandth_seconds).is_nil
    end

    should "write values that can't be converted as `nil` values" do
      subject.seconds = 1.2345
      assert_that(subject.ten_thousandth_seconds).is_not_nil
      assert_that(subject.seconds).is_not_nil

      assert_that { subject.seconds = true }.does_not_raise
      assert_that(subject.seconds).is_nil
      assert_that(subject.ten_thousandth_seconds).is_nil
    end

    should "handle decimals with less significant digits" do
      subject.seconds = 1.12
      assert_that(subject.ten_thousandth_seconds).equals(11200)
      assert_that(subject.seconds).equals(1.12)
    end

    should "handle integers" do
      subject.seconds = 5
      assert_that(subject.ten_thousandth_seconds).equals(50000)
      assert_that(subject.seconds).equals(5.0)
    end

    should "handle decimals that are less than 1" do
      subject.seconds = 0.0001
      assert_that(subject.ten_thousandth_seconds).equals(1)
      assert_that(subject.seconds).equals(0.0001)
    end

    should "handle decimals with too many significant digits by rounding" do
      subject.seconds = 1.00005
      assert_that(subject.ten_thousandth_seconds).equals(10001)
      assert_that(subject.seconds).equals(1.0001)
    end

    should "handle repeating decimals" do
      subject.seconds = 1 / 3.0
      assert_that(subject.ten_thousandth_seconds).equals(3333)
      assert_that(subject.seconds).equals(0.3333)
    end
  end

  class TestHelpersTests < ReceiverSetupTests
    include MuchDecimal::TestHelpers

    desc "TestHelpers"
    subject { receiver_class.new }

    setup do
      receiver_class.decimal_as_integer(:seconds)
      receiver_class.decimal_as_integer(
        :other_seconds,
        source:    :integer_seconds,
        precision: @custom_precision
      )
    end

    let(:custom_precision) { Factory.integer(10) }

    should "provide helpers for testing that a class has decimal fields" do
      assert_decimal_as_integer(subject, :seconds)
      assert_decimal_as_integer(
        subject,
        :other_seconds,
        source:    :integer_seconds,
        precision: @custom_precision
      )
    end
  end
end
