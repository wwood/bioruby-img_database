#!/usr/bin/env ruby

require 'optparse'
require 'bio-logger'
require 'systemu'
require 'tempfile'
require 'progressbar'

if __FILE__ == $0 #needs to be removed if this script is distributed as part of a rubygem
  SCRIPT_NAME = File.basename(__FILE__); LOG_NAME = SCRIPT_NAME.gsub('.rb','')
  
  # Parse command line options into the options hash
  options = {
    :logger => 'stderr',
  }
  o = OptionParser.new do |opts|
    opts.banner = "
      Usage: #{SCRIPT_NAME} {cog} --img-database <some.sqlite3> --img-directory <img_flatfiles_basedir>
      
      Upload a table of data to a local sqlite3 database. \n\n"
      
    opts.on("--img-database IMG_DATABASE", "sqlite3 file that contains the data [required]") do |arg|
      options[:database_file] = File.absolute_path(arg)
    end
    opts.on("--img-directory DIRECTORY", "Directory containing the data [required]") do |arg|
      options[:img_directory] = arg
    end


    # logger options
    opts.separator "\n\tVerbosity:\n\n"
    opts.on("-q", "--quiet", "Run quietly, set logging to ERROR level [default INFO]") {Bio::Log::CLI.trace('error')}
    opts.on("--logger filename",String,"Log to file [default #{options[:logger]}]") { |name| options[:logger] = name}
    opts.on("--trace options",String,"Set log level [default INFO]. e.g. '--trace debug' to set logging level to DEBUG"){|s| Bio::Log::CLI.trace(s)}
  end; o.parse!
  if ARGV.length != 1
    $stderr.puts o
    exit 1
  end
  # Setup logging. bio-logger defaults to STDERR not STDOUT, I disagree
  Bio::Log::CLI.logger(options[:logger]); log = Bio::Log::LoggerPlus.new(LOG_NAME); Bio::Log::CLI.configure(LOG_NAME)
  
  
  
  data_file_path = lambda {|taxon_id| File.join(taxon_id, "#{taxon_id}.cog.tab.txt")}
  table_name = 'cogs'
  
  Dir.chdir(options[:img_directory])
  img_directories = Dir.glob('*')
  log.info "Found #{img_directories.length} directories that look like they contain IMG data"
  progress = ProgressBar.new('img', img_directories.length)

  Tempfile.open('img_upload') do |csv_tempfile|
    csv_tempfile.close
    
    primary_key = 1
    img_directories.each do |taxon_directory|
      if !taxon_directory.match(/^\d+$/) or !File.directory?(taxon_directory)
        log.warn "Skipping file/directory #{taxon_directory} as it doesn't seem like a sub-directory with genome data in it"
        next
      end
      
      data_path = data_file_path.call taxon_directory
      if !File.exist?(data_path)
        log.warn "Data file not found so skipping this sub-directory: #{data_path}"
        next
      end
      
      # How many lines in this file?
      num_lines = `tail -n+2 '#{data_path}' |wc -l`.to_i
      log.debug "Found #{num_lines} lines of data in the data file"
      
      # Output this file and the primary keys to the tempfile
      Tempfile.open('seq_temp') do |seq_temp|
        seq_temp.close
        `seq #{primary_key} #{primary_key+num_lines-1} >#{seq_temp.path}`
        
        `tail -n+2 '#{data_path}' |paste '#{seq_temp.path}' - >>#{csv_tempfile.path}`
      end
      
      primary_key += num_lines

      #progress.inc
    end
    progress.finish
  
  
    log.info "Importing the temporary CSV file into the database"
    command = "sqlite3 #{options[:database_file]}"
    stdin = ".mode tabs\n.import #{csv_tempfile.path} #{table_name}\n"
    status, stdout, stderr = systemu command, 0=>stdin
    unless status.exitstatus == 0
      raise Exception, "Some kind of error running sqlite3 import. STDERR was #{stderr}"
    end
  end
  log.info "Seem to have completed the upload successfully"
  
end #end if running as a script