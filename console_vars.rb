require 'ostruct'

# this module encapsulate a common interface for common console application
# variables and allows the implementor to extend it with its own items, such
# as command line options.

module ConsoleVars
  def console_vars
    @console_vars ||= OpenStruct.new(verbose:false, dryrun:false, use_sudo:false)
  end

  def verbose
    console_vars.verbose
  end

  def dryrun
    console_vars.dryrun
  end

  def use_sudo
    console_vars.use_sudo
  end

  def vars_to_h
    console_vars.to_h
  end

  # Merge a set of vars (from hash) into this struct
  def vars_merge(**vars_h)
    ret_vars = console_vars.clone
    vars_h.each do |key, value|
      ret_vars[key.to_sym] = value
    end
    ret_vars
  end

  # Merge this struct with new vars (from hash)
  def vars_merge!(**vars_h)
    vars_h.each do |key, value|
      console_vars[key.to_sym] = value
    end
  end
end