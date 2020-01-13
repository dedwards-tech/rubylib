require 'test/unit'
require 'optparse'
require_relative File.join('..', 'console_utils')

class UnitTest_ConsoleUtils < Test::Unit::TestCase
  def test_1_cli_helper_simple
    my_cli = CliHelper.new
    my_cli.new_simple('t_var1', 'tvar1_value', '--tvar1 [STR]',
                      'Test1-tvar1 Unit Test var')
    argv = ['--tvar1', 'argv_value1']
    my_args = my_cli.get_args(argv)
    assert_equal('argv_value1', my_args.t_var1, 'ERR: t_var1 arg value mismatch')
  end

  def test_2_cli_helper_with_block
    my_cli = CliHelper.new
    my_cli.new_simple('t_var2', 'tvar2_value', '--tvar2 [STR]',
                      'Test2-tvar2 Unit Test var') do |opt_arg|
      assert_equal('argv_value2', my_cli.get_value(opt_arg), 'ERR: t_var2 arg value mismatch')
      my_cli.set_value(opt_arg, 'argv_value3')
    end
    argv = ['--tvar2', 'argv_value2']
    my_args = my_cli.get_args(argv)
    assert_equal('argv_value3', my_args.t_var2, 'ERR: t_var2 arg value block set mismatch')
  end

  def test_3_cli_helper_with_reject
    my_cli = CliHelper.new
    my_cli.new_simple('t_var3', 'tvar3_value', '--tvar3 [STR]',
                      'Test3-tvar3 Unit Test var') do |opt_arg|
      value = my_cli.get_value(opt_arg)
      assert_equal('argv_value3', value, 'ERR: t_var3 arg value mismatch')
      my_cli.reject(opt_arg)
    end
    argv = ['--tvar3', 'argv_value3']
    assert_raise(OptionParser::InvalidArgument,
                 "ERR: reject() should have raised Invalid Argument exception.") do
      my_args = my_cli.get_args(argv)
      assert_equal('argv_value3', my_args.t_var3, 'ERR: t_var3 arg value block set mismatch')
    end
  end

  def test_4_cli_helper_no_args
    my_cli = CliHelper.new
    my_cli.new_simple('t_var4', 'tvar4_value', '--tvar4 [STR]',
                      'Test4-tvar4 Unit Test var')
    argv = []
    my_args = my_cli.get_args(argv)
    assert_not_nil(my_args, 'ERR: arguments should be empty')
  end

  def test_5_cli_helper_invalid_arg
    my_cli = CliHelper.new
    my_cli.new_simple('t_var5', 'tvar5_value', '--tvar5 [STR]',
                      'Test5-tvar5 Unit Test var')
    argv = ['--no-arg', 'testing123']
    assert_raise(OptionParser::InvalidOption, "ERR: should have thrown invalid option exception for invalid arg") { my_cli.get_args(argv) }
  end
end