require 'test/unit'
require_relative File.join('..', 'shell_exec')

# test the ability to create a new class from the ShellExec module.
# and maintain consistent API and programming model.
#

class UnitTest_ModuleShellExec < Test::Unit::TestCase
  class UnitTest_ShellExec
    include ShellExec
    def initialize(**opts)
      new_shell(verbose:true, dryrun:false, use_sudo:true, **opts)
    end

    def alt_shell_1(**opts)
      # TODO: implement a new shell "handler" and make sure its extension capabilities work the way you expect.
    end
  end

  def test_1_basic_init
    my_shell = UnitTest_ShellExec.new
    assert_equal(true, my_shell.verbose,  'global var :verbose not set')
    assert_equal(false, my_shell.dryrun,  'global var :dryrun not set')
    assert_equal(true, my_shell.use_sudo, 'global var :use_sudo not set')
    assert_equal(false, my_shell.bin_output,  'global var :bin_output not set to default: false')

    out_str, exit_code = my_shell.cmd_exec('uname -a')
    assert_equal(0, exit_code)
    assert_not_equal('', out_str)

    out_bin, exit_code = my_shell.cmd_exec('uname -a', verbose:true, bin_output:true)
    assert_equal(0, exit_code)
    assert_not_nil(out_bin)
  end

  def test_2_switch_shell_impl

  end
end