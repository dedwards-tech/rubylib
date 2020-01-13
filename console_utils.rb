require 'optparse'
require 'ostruct'

module ConsoleUtils
  def set_verbose(value=true)
    @verbose = value
  end

  def is_verbose
    @verbose ||= false
  end

  def set_dryrun(value=true)
    @dryrun = value
  end

  def is_dryrun
    @dryrun ||= false
  end
end


# Design goals:
#  * use object to directly reference argument vars
#  * make block initializers optional for most simple arguments
#

module CliOptionBase
  def args_list
    @args_list ||= []
  end

  def arg_parser
    @arg_parser ||= OptionParser.new
  end

  def reject(arg_opt)
    if arg_opt.fetch(:value, nil)
      raise OptionParser::InvalidArgument, "invalid value #{arg_opt[:value]} for #{arg_opt[:params[0]]}"
      #raise ArgumentError("invalid value #{arg_opt[:value]} for #{arg_opt[:params[0]]}")
    end
  end

  def set_required(arg_opt, req=true)
    arg_opt[:required] = req
  end

  def set_value(arg_opt, value=nil)
    arg_opt[:value] = value
  end

  def get_value(arg_opt)
    arg_opt[:value]
  end

  def get_name(arg_opt)
    arg_opt[:var_name]
  end

  def add_arg(var_name, init_value, long_arg, help_str)
    new_arg = { :var_name => var_name, :value => init_value, :params => [ long_arg, help_str ] }
    args_list.push(new_arg)
    new_arg
  end

  def get_args(argv=nil)
    if argv.nil?
      arg_parser.parse!
    else
      arg_parser.parse!(argv)
    end
    os_vars = {}
    args_list.each {|arg_opt| os_vars.merge!( { arg_opt[:var_name] => arg_opt[:value] } ) }
    OpenStruct.new(os_vars)
  end
end

class CliHelper
  include CliOptionBase
  attr_accessor :parser

  def initialize
    args_list
    arg_parser
  end

  def new_simple(var_name, init_value, long_arg, help_str, &block)
    this_arg = add_arg(var_name, init_value, long_arg, help_str, &block)
    arg_parser.on(long_arg, help_str) do |o|
      set_value(this_arg, o)
      yield(this_arg) if block_given?
    end
    this_arg
  end
end
