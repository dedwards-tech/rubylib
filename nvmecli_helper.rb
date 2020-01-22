require_relative 'linux_udevadm'

class NvmeCliHelper
  attr_accessor :dev_list
  attr_reader :sn_list
  attr_reader :max_timeout
  attr_reader :ns_alloc_b
  attr_reader :udevadm_cli

  def initialize(opts={})
    @dev_list    = []
    @sn_list     = opts.fetch(:sn_list,     [])
    @max_timeout = opts.fetch(:max_timeout, 9999999)

    # allow for skipping of device scan on remote host during init
    skip_find    = opts.fetch(:skip_find,   false)

    # default APL allocation unit for namespaces is 1GB, allow for override
    # TODO: make this based on some product family identifier like CSDP, CDRDP, etc.
    #
    @ns_alloc_b  = opts.fetch(:ns_alloc_bytes, 1073741824)
    super(opts)

    tinant_data, exit_code = _exec("sudo nvme --version")
    if exit_code == 0
      @version = tinant_data.getraw.strip.chomp
    else
      @version = 'unknown'
    end

    # allocate a udevadm cli helper, this will re-use the opt[:cmd_exec] option but
    # also supports re-use of opts within various commands that may need to be executed
    # concurrently.
    #
    @udevadm_cli = GathererLinuxUdevadm.new(opts)

    # collect all known system NVMe device information before running any cli commands.
    find_devices() unless skip_find
  end

  def each(&block)
    if block_given?
      dev_list.each { |device| block.call(device) }
    else
      dev_list
    end
  end

  # helper function to walk through a device namespaces and controller
  # id's for certain namespace routines like attach and detach
  #
  # example:
  #    _each_ns_ctrl([1, 2], [0]) {|ns_id, ctrl_id | [ 'stdout string', 0 ] }
  #
  def _each_ns_ctrl(ns_ids, ctrl_ids, &block)
    if block_given?
      success = true
      for ns_id in ns_ids do
        for ctrl_id in ctrl_ids do
          tinant_out, exit_code = block.call(ns_id, ctrl_id)
          if exit_code != 0
            success = false
          end
        end
      end
    else
      log.error { "no block given to _each_ns_ctrl()..."}
      success = false
    end

    success
  end

  def fetch(dev_node)
    ret_data = nil
    dev_list.each do |dev_data|
      if dev_data['dev'] == dev_node
        ret_data = dev_data
        break
      end
    end

    ret_data
  end

  # just execute detach namespace command line using strings for namespace id and controller id.
  def detach_ns(dev_node, ns_id, opts={})
    ctrl_id = opts.fetch(:ctrl_ids, "0,1")
    cmd_out, exit_code = _exec("sudo nvme detach-ns #{dev_node} -n #{ns_id} -c #{ctrl_id}", opts)
    exit_code == 0
  end

  # attach namespace, passing in a list of namespace identifiers and list of
  # controller id's.
  #
  def attach_ns(dev_node, ns_id, opts={})
    ctrl_id = opts.fetch(:ctrl_ids, "0,1")
    cmd_out, exit_code = _exec("sudo nvme attach-ns #{dev_node} -n #{ns_id} -c #{ctrl_id}", opts)
    exit_code == 0
  end

  def delete_ns(dev_node, ns_id, opts={})
    cmd_out, exit_code = _exec("sudo nvme delete-ns #{dev_node} -n #{ns_id} --timeout #{max_timeout}", opts)
    exit_code == 0
  end

  def identify_ns(dev_node, ns_id, opts={})
    id_ns_data = { 'dev' => dev_node, 'ns_id' => ns_id, 'blk_dev' => make_ns_dev(dev_node, ns_id) }

    tinant_out, exit_code = _exec("sudo nvme id-ns #{dev_node} -n #{ns_id} -o json", opts)
    if exit_code == 0
      id_ns_data.merge!(JSON.parse(tinant_out.getraw))

      # reflect the parsed data back to the tinant object
      tinant_out.setdata(id_ns_data)
    end

    id_ns_data
  end

  # turn a dev node and a namespace id into a namespace block device (linux)
  def make_ns_dev(dev_node, ns_id)
    "#{dev_node}n#{ns_id}"
  end

  # collect the following data:
  #  [
  #     { 'ns_id' => ##, 'blk_dev' => blk_dev },
  #  ]
  def list_ns(dev_node, opts={})
    ns_list = []

    tinant_out, exit_code = _exec("sudo nvme list-ns #{dev_node}", opts)
    if exit_code == 0
      ret_lines = tinant_out.getraw.split("\n")
      ret_lines.each do |ret_line|
        tokens = ret_line.split(":")
        if tokens.count == 2
          # (fingers crossed) assume namespace id's are in 0 to n order and that the value
          # is in hex form (0x##).
          ns_id = tokens[1].strip.to_i(16)
          ns_list.push({ 'ns_id' => ns_id, 'blk_dev' => make_ns_dev(dev_node, ns_id) })
        else
          log.warn { "unrecognized token string (IGNORING): #{ret_line}" }
        end
      end
      # reflect the parsed data back to the tinant object
      tinant_out.setdata(ns_list)
    end

    ns_list
  end

  # collect the following data:
  #  [
  #    { 'ns_id' => ##, 'blk_dev' => blk_dev, 'id_ns_data'  => ns_data },
  #  ]
  #
  def get_ns_data(dev_node, opts={})
    ns_list = list_ns(dev_node, opts)
    ns_list.each do |id_info|
      id_ns_data = identify_ns(dev_node, id_info['ns_id'])

      # add the identify namespace data to the ns_list
      id_info.merge!({ 'id_ns_data' => id_ns_data })

      # TODO: figure out how to detect when a namespace is attached or detached and add it to the data set
    end
    ns_list
  end

  def create_ns(dev_node, opts={})
    dev_data  = fetch(dev_node)
    success   = false
    unless dev_data.nil?
      # calculate command parameters against defaults and inputs
      tnvmcap  = dev_data['tnvmcap'].to_i

      flbas    = opts.fetch(:flbas, 0)       # there's always at least 1 flba entry, default=0
      nmic     = opts.fetch(:nmic,  1)       # shared namespaces default
      dps      = opts.fetch(:dps,   0)       # data protection settings; default 0

      # determine number of blocks to create the namespace with, default to whole drive
      nsze     = opts.fetch(:nsze)
      tcap     = opts.fetch(:tcap, nsze)     # same as nsze if not provided

      cmd_str  = "sudo nvme create-ns #{dev_node} --nsze #{nsze} --ncap #{tcap} --flbas #{flbas} "
      cmd_str += "--dps #{dps} --nmic #{nmic} --timeout #{max_timeout}"

      tinant_out, exit_code = _exec(cmd_str, opts)
      success = exit_code == 0
    end

    success
  end

  def rescan_ns(dev_node, opts={})
    success   = false
    dev_data  = fetch(dev_node)
    unless dev_data.nil?
      tinant_out, exit_code = _exec("sudo nvme ns-rescan #{dev_node}", opts)
      success = exit_code == 0
    end
    success
  end

  def is_sn_match(serial_num)
    # if there's no sn list then its always a match, otherwise
    # search the sn list for a match
    match = true
    if sn_list.count > 0
      # there is an sn list so presume it is NOT in the list and stop
      # checking once it is found.
      match = false
      sn_list.each do |sn_item|
        if sn_item.strip == serial_num
          match = true
          break
        end
      end
    end
    match
  end

  def get_lspci(pci_bdf, opts={})
    pci_data = { 'pci_bdf' => pci_bdf, 'wwid' => 'unknown' }

    tinant_out, exit_code = _exec("sudo lspci -v -s #{pci_bdf} | grep 'Device Serial Number'", opts)
    if exit_code == 0
      # sample output:
      #   Capabilities: [140] Device Serial Number 55-cd-2e-41-4f-85-6c-47
      #
      tokens = tinant_out.getraw.strip.split(':')
      if tokens.count > 1
        tokens = tokens[1].split(' ')
        tokens.each do |token|
          if token.include?('-')
            # all we want is the 8 byte PCIe device serial number - which is the drive WWID
            # and remove the dashes '-' between numbers
            pci_data['wwid'] = token.strip.gsub('-', '').upcase
            tinant_out.setdata(pci_data)
            break
          end
        end
      end
    end
    pci_data
  end

  # grab device detail data from a specific dev_node and package it into a self
  # contained struction - including PCIe details, and namespace details
  #
  # returns data in the form of:
  # [ device serial number, NVMe controller id, and controller data ]
  #
  # Controller data is as follows:
  #   { 'dev'       => char_dev_node,
  #     'cntlid'    => (integer) id of nvme controller,
  #     'path'      => udev_info[:path],
  #     'id_ctrl'   => node_data,
  #     'ns_data'   => get_ns_data()
  #     'udev_info' => udevadm.info_query()
  #     'udev_path' => udevadm.info_walk_by_path()
  #   }
  #
  def get_dev_details(dev_node, opts={})
    node_data = fetch(dev_node)

    # we have the basics, now we need pci and namespace details
    dev_sn    = node_data['sn'].strip
    ctrl_id   = node_data['cntlid']
    dev_node  = node_data['dev']

    # we get PCIe hierarchy, driver and other system details with udevadm
    udev_info = udevadm_cli.info_query(dev_node, opts)
    udev_path = udevadm_cli.info_walk_by_path(udev_info[:path], opts)
    ns_data   = get_ns_data(dev_node, opts)

    if udev_path.fetch(:dev_data, nil).nil?
      lspci_data = { 'pci_bdf' => 'unknown', 'wwid' => 'unknown' }
    else
      pci_bdf    = udev_path[:dev_data][1][:attributes]['KERNELS']
      lspci_data = get_lspci(pci_bdf, opts)
    end

    # encapsulate all the data
    ctrl_data = { 'dev'       => dev_node,
                  'cntlid'    => ctrl_id,   'path'      => udev_info[:path],
                  'id_ctrl'   => node_data,
                  'udev_info' => udev_info, 'udev_path' => udev_path,
                  'ns_data'   => ns_data,
                  'lspci'     => lspci_data }

    # return a set (array) of data for the device details
    [ dev_sn, ctrl_id, ctrl_data ]
  end

  # create new list keyed by device serial number
  # {
  #   "serial_num" => {
  #     "0"  => { ctrl_data from dev_details() }
  #     "1"  => { ctrl_data from dev_details() }
  #     ...
  #   },
  #   ...
  # }
  #
  def get_report(opts={})
    # allow for previous searches to be provided as input, otherwise use the list
    # found during initialization.
    #
    loc_list    = opts.fetch(:dev_list, @dev_list)
    report_data = {}
    loc_list.each do |node_data|
      dev_node  = node_data['dev']
      dev_sn, ctrl_id, ctrl_data = get_dev_details(dev_node, opts)

      # save the data to the report dictionary
      sn_data   = report_data.fetch("#{dev_sn}", nil)
      if sn_data.nil?
        # create a new entry in the report
        sn_data = {}
        report_data.merge!({ "#{dev_sn}" => sn_data })
      end

      # There should only be one data set per controller id, so dev_sn is a list of hashes
      # containing specific controller data.  Dual Host + Dual Port systems will have only one entry
      # where Single Host + Dual Port systems will have 2 entries.
      #
      sn_data.merge!({ "#{ctrl_id}" => ctrl_data })
    end

    report_data
  end

  def find_devices(opts={})
    # wipe the master lists in case this is called multiple times.
    @dev_list.clear
    @tinant_list.clear

    # grab a list of only char device nodes in the form of /dev/nvme?? (no namespaces)
    tinant_data, exit_code = _exec("sudo find /dev/ -type c -name 'nvme*' | grep '/dev/nvme'", opts)
    raw_out                = tinant_data.getraw
    unless raw_out.nil?
      device_nodes           = raw_out.split("\n")
      log.info { "found #{device_nodes.count} devices on host #{cmd_exec.call("hostname")}" }

      # take that list of dev nodes, grab the id controller information and parse it into
      # a key / value pair structure.
      for dev_node in device_nodes
        node_data             = { 'dev' => dev_node }
        ta_id_ctrl, exit_code = _exec("sudo nvme id-ctrl #{dev_node} -o json", opts)
        if exit_code == 0
          node_data.merge!(JSON.parse(ta_id_ctrl.getraw))
        end

        # check if the device serial number is in the list to scan details for
        if is_sn_match(node_data['sn'].strip)
          # now save the parsed data to the tinant "data" field for this command
          ta_id_ctrl.setdata(node_data)
          @dev_list.push(node_data)
          log.info { "FOUND device: #{node_data['dev']}, sn: #{node_data['sn'].strip}" }
        else
          log.info { "SKIPPING device: #{node_data['dev']}, sn: #{node_data['sn'].strip} (not found in sn list)" }
        end
      end
    else
      log.info { "no devices found" }
    end

    dev_list
  end
end
