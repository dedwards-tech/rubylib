require 'test/unit'
require_relative File.join('..', 'timestamp_ns')

class UnitTest_TimestampNS < Test::Unit::TestCase
  def test_1_timestamp_init
    puts("test case #{__method__.to_s} - exec")

    t_curr   = TimestampNS.new()
    t_int    = TimestampNS.new(t_curr)
    time_now = Time.now
    t_time   = TimestampNS.new(time_now)
    t_f      = BigDecimal(time_now.to_f * (10**9), 16).to_i
    puts(" -> t_curr: #{t_curr}, t_int: #{t_int}")
    puts(" -> time_now: #{time_now}, t_time: #{t_time}, t_f: #{t_f}")

    assert_equal(t_curr, t_int, "failed comparison: t_curr == t_int")
    assert_equal(t_time, t_f, "failed comparison: t_time(now) == now.t_f")
  end

  def test_2_timestamp_comparison
    puts("test case #{__method__.to_s} - exec")

    t_prev   = TimestampNS.new()
    sleep(1.0)
    t_now    = TimestampNS.new()
    puts(" -> t_prev: #{t_prev}, t_now: #{t_now}")

    assert_block("failed comparison: t_now > t_prev")   { t_now > t_prev }
    assert_block("failed comparison: t_prev == t_prev") { t_prev == t_prev }
    assert_block("failed comparison: t_prev < t_now")   { t_prev < t_now }
  end

  def test_3_timestamp_addition
    puts("test case #{__method__.to_s} - exec")

    t_prev = TimestampNS.new
    sleep(0.001)
    t_now = TimestampNS.new
    puts(" -> t_prev: #{t_prev}, t_now: #{t_now}")

    # integer arithmatic
    assert_not_equal(t_now, t_now + 1, "failed add and compare integer: t_now != t_now + 1")
    assert_not_equal(t_now, 1 + t_now, "failed add and compare integer: t_now != 1 + t_now")

    # float arithmatic - this is tricky because float is extremely inaccurate.
    # a single nanosecond difference can lose precision!!!
    assert_not_equal(t_now, BigDecimal(1.0, 16) + t_now, "failed add and compare BigDecimal: t_now != 1.0 + t_now")
    assert_not_equal(t_now, t_now + BigDecimal(1.0, 16), "failed add and compare BigDecimal: t_now != t_now + 1.0")

    assert_block("failed add and compare: t_now + t_prev > t_prev") do
      puts("addition: t_now (#{t_now}) + t_prev (#{t_prev}) = #{t_now + t_prev}")
      t_now + t_prev > t_prev
    end

  end

  def test_4_timestamp_subtract
    puts("test case #{__method__.to_s} - exec")

    t_prev = TimestampNS.new
    sleep(0.010)
    t_now = TimestampNS.new
    puts(" -> t_prev: #{t_prev}, t_now: #{t_now}")

    # integer arithmatic
    assert_not_equal(t_now, t_now - 1, "failed subtract and compare integer: t_now != t_now - 1")
    assert_not_equal(t_now, 1 - t_now, "failed subtract and compare integer: t_now != 1 - t_now")

    # float arithmatic - this is tricky because float is extremely inaccurate.
    # a single nanosecond difference can lose precision!!!
    assert_not_equal(t_now, BigDecimal(1.0, 16) - t_now, "failed subtract and compare BigDecimal: t_now != 1.0 - t_now")
    assert_not_equal(t_now, t_now - BigDecimal(1.0, 16), "failed subtract and compare BigDecimal: t_now != t_now - 1.0")

    assert_block("failed subtract and compare: t_now - t_prev > 0") do
      puts("subtract: t_now (#{t_now}) - t_prev (#{t_prev}) = #{t_now - t_prev}")
      t_now - t_prev > 0
    end
  end

  def test_5_timestamp_multiply
    puts("test case #{__method__.to_s} - exec")

    t_prev = TimestampNS.new
    sleep(0.010)
    t_now = TimestampNS.new
    puts(" -> t_prev: #{t_prev}, t_now: #{t_now}")

    # integer arithmatic
    assert_not_equal(t_now, t_now * 5, "failed multiply and compare integer: t_now != t_now * 5")
    assert_not_equal(t_now, 5 * t_now, "failed multiply and compare integer: t_now != 5 * t_now")

    # float arithmatic - this is tricky because float is extremely inaccurate.
    # a single nanosecond difference can lose precision!!!
    assert_not_equal(t_now, BigDecimal(5.0, 16) * t_now, "failed multiply and compare BigDecimal: t_now != 5.0 * t_now")
    assert_not_equal(t_now, t_now * BigDecimal(5.0, 16), "failed multiply and compare BigDecimal: t_now != t_now * 5.0")

    assert_block("failed multiply and compare: t_now * 5 > t_now") do
      puts("multiply: t_now (#{t_now}) * 5 = #{t_now * 5}")
      t_now * 5 > t_now
    end
  end

  def test_6_timestamp_divide
    puts("test case #{__method__.to_s} - exec")

    t_prev = TimestampNS.new
    sleep(0.010)
    t_now = TimestampNS.new
    puts(" -> t_prev: #{t_prev}, t_now: #{t_now}")

    # integer arithmatic
    assert_equal(t_now, t_now / 1, "failed divide and compare integer: t_now == t_now / 1")
    assert_equal(0, 1 / t_now, "failed divide and compare integer: 1 / t_now == 0")

    # float arithmatic - this is tricky because float is extremely inaccurate.
    # a single nanosecond difference can lose precision!!!
    assert_equal(t_now, t_now / BigDecimal(1.0, 16), "failed divide and compare BigDecimal: t_now == t_now / 1.0")
    assert_equal(0, BigDecimal(1.0, 16) / t_now, "failed divide and compare BigDecimal: 1.0 / t_now == 0")

    assert_block("failed divide and compare: t_now / 1 == t_now") do
      puts("divide: t_now (#{t_now}) / 1 = #{t_now / 1}")
      t_now / 1 == t_now
    end
  end
end
