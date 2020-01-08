require 'bigdecimal/util'
require 'time'

module TimestampNumeric
  include Comparable

  def timestamp(value=nil)
    if value.nil?
      # make sure there's always an initial value
      @timestamp ||= 0
    else
      unless (value.is_a?(self.class) or value.is_a?(Numeric))
        raise TypeError, "#{value.class} can't be coerced into #{self.class}"
      end
      @timestamp = value.to_i
    end
  end

  def to_s
    timestamp.to_s
  end

  def inspect
    timestamp
  end

  def coerce(other)
    [ self.class.new(other), self ]
  end

  def <=>(other)
    if other.is_a?(self.class)
      timestamp <=> other.timestamp
    elsif other.is_a?(Numeric)
      timestamp <=> other
    else
      raise TypeError, "#{other.class} comparator (<=>): other cant be coerced to #{self.class}"
    end
  end

  def +(other)
    if other.is_a?(self.class)
      self.class.new(timestamp + other.timestamp)
    elsif other.is_a?(Numeric)
      self.class.new(timestamp + other)
    else
      if other.respond_to? :coerce
        a, b = other.coerce(self)
        a + b
      else
        raise TypeError, "#{other.class} addition: cant be coerced into #{self.class}"
      end
    end
  end

  def -(other)
    if other.is_a?(self.class)
      self.class.new(timestamp - other.timestamp)
    elsif other.is_a?(Numeric)
      self.class.new(timestamp - other)
    else
      if other.respond_to? :coerce
        a, b = other.coerce(self)
        a - b
      else
        raise TypeError, "#{other.class} subtract: cant be coerced into #{self.class}"
      end
    end
  end

  def *(other)
    if other.is_a?(self.class)
      self.class.new(timestamp * other.timestamp)
    elsif other.is_a?(Numeric)
      self.class.new(timestamp * other)
    else
      if other.respond_to? :coerce
        a, b = other.coerce(self)
        a * b
      else
        raise TypeError, "#{other.class} cant be coerced into #{self.class}"
      end
    end
  end

  def /(other)
    if other.is_a?(self.class)
      self.class.new(timestamp / other.timestamp)
    elsif other.is_a?(Numeric)
      self.class.new(timestamp / other)
    else
      if other.respond_to? :coerce
        a, b = other.coerce(self)
        a / b
      else
        raise TypeError, "#{other.class} cant be coerced into #{self.class}"
      end
    end
  end
end

class TimestampNS
  include TimestampNumeric

  def _bigd_precision
    16
  end

  def time_to_ns(time_t)
    raise ArgumentError('time_t arg MUST implement to_f') unless time_t.respond_to?(:to_f)
    time_f_to_ns(time_t.to_f)
  end

  def time_f_to_ns(time_f)
    # don't allow floating point math errors to affect conversion to nano-seconds
    BigDecimal(time_f * (10**9), _bigd_precision).to_i
  end

  def initialize(time_in=nil)
    if time_in.nil?
      # convert the current time to nano-seconds since epoch,
      # only if @time_ns is not initialized
      time_ns = time_f_to_ns(Time.now.to_f)
    else
      if time_in.is_a?(Time)
        time_ns = time_f_to_ns(time_in.to_f)
      elsif time_in.is_a?(Float)
        raise TypeError, "cannot use Float as a value of time in nano-seconds"
      else
        time_ns = time_in
      end
    end

    # initialize module var: @timestamp defined in TimestampNumeric module
    timestamp(time_ns)
  end

  def method_missing(name, *args, &block)
    puts("NOTE: passing method :#{name} to timestamp class #{timestamp.class}, args=#{args.to_s}")
    # any math, coersion or other methods not implemented by this class
    # will forward method calls to the instance var
    timestamp.send(name, *args, &block)
  end
end