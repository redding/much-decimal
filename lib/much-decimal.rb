require 'much-plugin'

require 'much-decimal/version'

module MuchDecimal
  include MuchPlugin

  DEFAULT_PRECISION = 2.freeze

  def self.integer_to_decimal(integer, precision)
    if integer.respond_to?(:to_i) && !integer.to_s.empty?
      base_10_modifier = (10.0 ** precision)
      integer.to_i / base_10_modifier
    end
  end

  def self.decimal_to_integer(decimal, precision)
    if decimal.respond_to?(:to_f) && !decimal.to_s.empty?
      base_10_modifier = (10.0 ** precision)
      (decimal.to_f * base_10_modifier).round.to_i
    end
  end

  plugin_included do
    extend ClassMethods
  end

  module ClassMethods

    def decimal_as_integer(attribute, options = nil)
      options ||= {}
      source    = options[:source] || "#{attribute}_as_integer"
      precision = (options[:precision] || DEFAULT_PRECISION).to_i

      define_method(attribute) do
        integer = self.send(source)
        MuchDecimal.integer_to_decimal(integer, precision)
      end

      define_method("#{attribute}=") do |decimal|
        integer = MuchDecimal.decimal_to_integer(decimal, precision)
        self.send("#{source}=", integer)
      end
    end

  end

  module TestHelpers
    include MuchPlugin

    plugin_included do
      include InstanceMethods

      require 'assert/factory'
    end

    module InstanceMethods

      def assert_decimal_as_integer(subject, attribute, options = nil)
        options ||= {}
        source    = options[:source] || "#{attribute}_as_integer"
        precision = (options[:precision] || DEFAULT_PRECISION).to_i

        value = Assert::Factory.float
        subject.send("#{attribute}=", value)

        exp = MuchDecimal.decimal_to_integer(value, precision)
        assert_equal exp, subject.send(source)
        exp = MuchDecimal.integer_to_decimal(exp, precision)
        assert_equal exp, subject.send(attribute)
      end

    end

  end

end
