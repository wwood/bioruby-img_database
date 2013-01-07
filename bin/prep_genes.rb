#!/usr/bin/env ruby

require 'optparse'
require 'bio-logger'
require 'bio'
require 'progressbar'

if __FILE__ == $0 #needs to be removed if this script is distributed as part of a rubygem
  SCRIPT_NAME = File.basename(__FILE__); LOG_NAME = SCRIPT_NAME.gsub('.rb','')
  
  # Parse command line options into the options hash
  options = {
    :logger => 'stderr',
  }
  o = OptionParser.new do |opts|
    opts.banner = "
      Usage: #{SCRIPT_NAME} -d <img_folder>
      
      Given a folder that contains folders of IMG data (1 of these subfolders for each taxon, each including a .genes.fna file),
      output a CSV file that has the columns [primary_key, gene_id, taxon_id, gene_description]
      which can then be imported directly into an SQL database \n\n"
      
    opts.on("-d", "--img-directory DIRECTORY", "Directory containing the data [required]") do |arg|
      options[:img_directory] = arg
    end

    # logger options
    opts.separator "\nVerbosity:\n\n"
    opts.on("-q", "--quiet", "Run quietly, set logging to ERROR level [default INFO]") {Bio::Log::CLI.trace('error')}
    opts.on("--logger filename",String,"Log to file [default #{options[:logger]}]") { |name| options[:logger] = name}
    opts.on("--trace options",String,"Set log level [default INFO]. e.g. '--trace debug' to set logging level to DEBUG"){|s| Bio::Log::CLI.trace(s)}
  end; o.parse!
  if ARGV.length != 0
    $stderr.puts o
    exit 1
  end
  # Setup logging. bio-logger defaults to STDERR not STDOUT, I disagree
  Bio::Log::CLI.logger(options[:logger]); log = Bio::Log::LoggerPlus.new(LOG_NAME); Bio::Log::CLI.configure(LOG_NAME)
  
  
  Dir.chdir(options[:img_directory])
  img_directories = Dir.glob('*')
  log.info "Found #{img_directories.length} directories that look like they contain IMG data"
  progress = ProgressBar.new('img', img_directories.length)
  
  primary_key = 1
  img_directories.each do |taxon_directory|
    if !taxon_directory.match(/^\d+$/)
      log.warn "Skipping file/directory #{taxon_directory} as it doesn't seem like a sub-directory with genome data in it"
      next
    end
    
    genes_file = File.join(taxon_directory, "#{taxon_directory}.genes.faa")
    if !File.exist?(genes_file)
      log.warn "Taxon genes.faa file not found, skipping this sub-directory: #{genes_file}"
      next
    end
    $stderr.puts taxon_directory
    $stderr.puts genes_file
    
    begin
      Bio::FlatFile.open(genes_file).each do |entry|
        
        puts '"'+[
          primary_key,
          entry.definition.split(/\s+/)[0],
          taxon_directory,
          entry.definition.gsub('"','\''),
        ].join('","')+'"'
        primary_key += 1
      end
    rescue Bio::FlatFile::UnknownDataFormatError => e
      log.warn "Fasta file #{genes_file} not auto-detected properly. Is it an empty file? Skipping."
    end
    progress.inc
  end
  progress.finish
end #end if running as a script