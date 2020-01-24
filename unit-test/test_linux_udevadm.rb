require 'test/unit'
require_relative File.join('..', 'linux_udevadm')

class UnitTest_LinuxUdevadmHelper < Test::Unit::TestCase
  def test_1_local_udevadm
    # we're going to swap out the usual local shell exec and send it a simulated
    # linux exec so we can give the unit test pre-canned data from a live system
    # without requiring execution on the live system.  Our intent is to test the
    # parsing logic, not the shell execution logic.
    #
    udev_test_data = [ {} ]
    sim_exec  = LinuxExecSimulator.new(sim_data:udev_test_data)
    udev_hlpr = LinuxUdevadmHelper.new(verbose:true, cmd_exec:sim_exec)
    assert_not_nil(udev_hlpr.cmd_exec, "ERR: cmd_exec not initialized.")
    assert_not_empty(udev_hlpr.kernel, "ERR: linux kernel version not initialized.")
    assert_not_empty(udev_hlpr.version, "ERR: udevadm version not initialized.")
  end
end