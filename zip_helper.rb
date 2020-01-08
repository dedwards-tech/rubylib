require 'pathname'
require 'fileutils'

# this is from the rubyzip gem
require 'zip'

module ZipHelper
  # return any recognized compression types from the file extension.
  # it is recommended you use File.basename(file_path) to avoid folders with
  # dots '.' in their name - supposed a folder was decompressed as <path.tgz/folder/file.tgz>
  #
  def ZipHelper.get_comp_type(file_name)
    compr_type = nil

    # TODO: add support for other compressed file types like tar / tgz / 7z
    #supported  = [ '.tgz', '.tar.gz', '.gz', '.zip', '.7z' ]
    supported  = [ '.zip' ]
    supported.each do |compr_ext|
      if file_name.end_with?(compr_ext)
        compr_type = compr_ext
        break
      end
    end
    compr_type
  end

  def ZipHelper.uncompress(file_name, destination='.')
    success = false
    zip_ext = zip.get_comp_type(File.basename(file_name))
    unless zip_ext.nil?
      if (destination != '.') && (destination != '..')
        FileUtils.mkdir_p(destination) unless Dir.exist?(destination)
      end
      Zip::File.open(file_name) do |zip_file|
        zip_file.each do |z_file|
          f_path = File.join(destination, z_file.name)
          d_path = File.dirname(f_path)
          FileUtils.mkdir_p(d_path) unless Dir.exist?(d_path)
          zip_file.extract(z_file, f_path) unless File.exist?(f_path)
        end
      end
      # this isn't a verified success, it just means it completed without any exceptions
      success = true
    end
    success
  end

  def ZipHelper.compress(file_name, destination=nil)
    success = false
    if destination.nil?
      file_path   = Pathname.new(file_name)
      file_ext    = file_path.basename.extname
      destination = file_path.to_s.sub(file_ext, '.zip')
    end

    raise RuntimeError, "unimplemented method #{self.class.name}::#{__method__.to_s}; file:#{file_name}, destination:#{destination}"
    success
  end
end