require_relative 'linux_exec_helper'

class LinuxUdevadmHelper < LinuxExecHelper
  attr_reader :kernel
  def initialize(**opts)
    super

    # copy default kernel version to kernel attr before we use the
    # version string for our own purposes.
    @kernel = version

    # set the version string to udevadm version
    ret_str, exit_code = cmd_exec("udevadm --version")
    if exit_code == 0
      @version = ret_str.strip.chomp
    else
      @version = 'unknown'
    end
  end

  # udevadm info -q <what> -n <dev_node>
  #
  # The default is to grab all info for the dev_node.
  #
  # NOTE: this returns an interpreted hash of the output data.
  #
  def info_query(dev_node, **opts)
    what      = opts.fetch(:what, 'all')
    hash_data = { :version => version, :path => nil, :name => nil, :info => {} }

    ret_str, exit_code = cmd_exec("udevadm info -q #{what} -n #{dev_node}", opts)
    if exit_code == 0
      props_list      = ret_str.split("\n")
      props_list.each do |prop_line|
        type = prop_line[0..1]        # one char + ':'
        data = prop_line[3..-1].strip # skip the first 3 chars and take the rest for data
        if type.eql?('P:')
          # sample:
          # P: /devices/pci0000:00/0000:00:03.2/0000:06:00.0/0000:07:03.0/0000:0b:00.0/0000:0c:0a.0/0000:17:00.0/nvme/nvme0
          #
          hash_data[:path] = data
        elsif type.eql?('N:')
          # sample:
          #   N: nvme0
          #
          hash_data[:name] = data
        elsif type.eql?('E:')
          # sample:
          #  E: DEVNAME=/dev/nvme0
          #  E: DEVPATH=/devices/pci0000:00/0000:00:03.2/0000:06:00.0/0000:07:03.0/0000:0b:00.0/0000:0c:0a.0/0000:17:00.0/nvme/nvme0
          #  E: MAJOR=240
          #  E: MINOR=0
          #  E: SUBSYSTEM=nvme
          #
          tokens = data.split('=')
          if tokens.count == 2
            name   = tokens[0].strip.chomp
            value  = tokens[1].strip.chomp
          else
            puts("unrecognized 'E' property format #{data}")
            name   = 'unknown'
            value  = data
          end
          hash_data[:info].merge!({ "#{name}" => value })
        else
          puts("unrecognized property type found #{type} => #{data}")
          # create an :unknown list if we find any unknowns - normally this should never be there
          hash_data[:info][:unknown] = [] if hash_data[:info].fetch(:unknown, nil).nil?
          hash_data[:info][:unknown].push({ "#{type}" => data })
        end
      end
    end
    hash_data
  end

  # Break the list of strings into a set of path segments separated by an empty line.
  # The first segment being the device followed by each parent sub-system.
  # This script will return a hash structure something like the following:
  #
  # { :path => dev_path (passed in), dev_data => [] }
  # [0] = device at dev_path
  #   sample:
  #     KERNEL=="nvme0"
  #     SUBSYSTEM=="nvme"
  #     DRIVER==""
  #     ATTR{transport}=="pcie"
  #     ...
  #
  # [1]..[n] = each parent in the device path, where each key / value pair will be
  #            converted to a hash as "key" => "value"
  #   sample:
  #     KERNELS=="0000:17:00.0"
  #     SUBSYSTEMS=="pci"
  #     DRIVERS=="nvme"
  #     ATTRS{irq}=="142"
  #     ...
  #
  def info_walk_by_path(dev_path, **opts)
    hash_data = { :version => version, :dev_data => [] }
    ret_str, exit_code = cmd_exec("udevadm info -a -p #{dev_path}", opts)
    if exit_code == 0
      segment_data = nil
      props_list   = ret_str.split("\n")
      props_list.each do |prop_line|
        prop_line.strip!
        if prop_line.start_with?('looking at ')
          # new segment, add the previous segment to the main list if its not the first.
          hash_data[:dev_data].push(segment_data) unless segment_data.nil?
          tokens = prop_line.split("'")
          if tokens.count > 2
            segment_data = { :path => tokens[1], :attributes => {} }
            # TODO: log this info for debug purposes - new segment
          else
            # TODO: find a way to move this out of here
            puts("WARNING: #{__method__.to_s}() unrecognized line format, ignoring: #{prop_line}")
            segment_data = nil
          end
        else
          if segment_data.nil?
            # ignore the line when segment_data is not initialized
            # TODO: add debug message here - but don't use puts
          elsif prop_line.strip.eql?('')
            # skip this quietly
          else
            # continue adding key / value pairs to the current segment
            tokens = prop_line.split('==')
            if tokens.count == 2
              key   = tokens[0].strip
              # strip quotes from the value string
              value = tokens[1].strip[1..-2]
              # flatten the ATTR?{key}=="value" with the KERNEL?=="value", etc and treat them
              # as a list of attributes in key / value form
              if key.start_with?('ATTR')
                # its an attribute key, strip the attr?{actual_attr} fields
                key.sub!('ATTRS{', '') if key.start_with?('ATTRS{')
                key.sub!('ATTR{', '')  if key.start_with?('ATTR{')
                # remove the last '}' char
                key = key[0..-2]
              end
              # merge the key / value store - any duplicates will be over written!
              segment_data[:attributes].merge!( { "#{key}" => value } )
            else
              puts("WARNING: #{__method__.to_s}() found unrecognized line pattern (IGNORING): #{prop_line}")
            end
          end
        end
      end
    end
    hash_data
  end
end
