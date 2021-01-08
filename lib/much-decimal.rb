# frozen_string_literal: true

require "much-decimal/version"
require "much-mixin"

module MuchDecimal
  include MuchMixin

  DEFAULT_PRECISION = 2

  def self.integer_to_decimal(integer, precision)
    if integer.respond_to?(:to_i) && !integer.to_s.empty?
      base_10_modifier = (10.0**precision)
      integer.to_i / base_10_modifier
    end
  end

  def self.decimal_to_integer(decimal, precision)
    if decimal.respond_to?(:to_f) && !decimal.to_s.empty?
      base_10_modifier = (10.0**precision)
      (decimal.to_f * base_10_modifier).round.to_i
    end
  end

  mixin_class_methods do
    def decimal_as_integer(attribute, source: nil, precision: nil)
      source ||= "#{attribute}_as_integer"
      precision = (precision || DEFAULT_PRECISION).to_i

      class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
        def #{attribute}
          MuchDecimal.integer_to_decimal(#{source}, #{precision})
        end

        def #{attribute}=(decimal_value)
          self.#{source} =
            MuchDecimal.decimal_to_integer(decimal_value, #{precision})
        end
      RUBY
    end
  end
end

module MuchDecimal::TestHelpers
  include MuchMixin

  mixin_included do
    require "assert/factory"
  end

  mixin_instance_methods do
    def assert_decimal_as_integer(
          subject,
          attribute,
          source: nil,
          precision: nil)
      source ||= "#{attribute}_as_integer"
      precision = (precision || MuchDecimal::DEFAULT_PRECISION).to_i

      value = Assert::Factory.float
      subject.public_send("#{attribute}=", value)

      integer = MuchDecimal.decimal_to_integer(value, precision)
      assert_that(subject.public_send(source)).equals(integer)
      assert_that(subject.public_send(attribute))
        .equals(MuchDecimal.integer_to_decimal(integer, precision))
    end
  end
end
