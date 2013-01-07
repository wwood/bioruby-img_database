#!/usr/bin/env ruby

require 'optparse'
require 'bio-logger'
require 'csv'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__),'..','lib'))
require 'bio-img_database'

# $:.push File.join(ENV['HOME'],'git','bioruby-taxonomy_definition_files','lib')
# require 'bio-taxonomy_definition_files' #has IMG taxonomy parser file

if __FILE__ == $0 #needs to be removed if this script is distributed as part of a rubygem
  SCRIPT_NAME = File.basename(__FILE__); LOG_NAME = SCRIPT_NAME.gsub('.rb','')
  
  # Parse command line options into the options hash
  options = {
    :logger => 'stderr',
  }
  o = OptionParser.new do |opts|
    opts.banner = "
      Usage: #{SCRIPT_NAME} <arguments>
      
      Description of what this program does...\n\n"
      
    opts.on("-d", "--img-database IMG_DATABASE", "sqlite3 file that contains the data [required]") do |arg|
      options[:database_file] =  arg
    end
    opts.on("--img-base-directory PATH", "Path to where the IMG genome data resides e.g. '/srv/whitlam/bio/db/img/4.0/genomes/all' [required]") do |arg|
      options[:img_base_directory] =  arg
    end

    # logger options
    opts.separator "\nVerbosity:\n\n"
    opts.on("-q", "--quiet", "Run quietly, set logging to ERROR level [default INFO]") {Bio::Log::CLI.trace('error')}
    opts.on("--logger filename",String,"Log to file [default #{options[:logger]}]") { |name| options[:logger] = name}
    opts.on("--trace options",String,"Set log level [default INFO]. e.g. '--trace debug' to set logging level to DEBUG"){|s| Bio::Log::CLI.trace(s)}
  end; o.parse!
  if ARGV.length != 0 or options[:database_file].nil? or option[:img_base_directory].nil?
    $stderr.puts o
    exit 1
  end
  # Setup logging. bio-logger defaults to STDERR not STDOUT, I disagree
  Bio::Log::CLI.logger(options[:logger]); log = Bio::Log::LoggerPlus.new(LOG_NAME); Bio::Log::CLI.configure(LOG_NAME)
  
  
  # Connect to the DB
  Bio::IMG::Database.connect options[:database_file]
  
  
  folders = Dir.entries.select{|e| e.match(/^\d+$/)}
  log.info "Found #{folder.length} different folders to process"
  progress = ProgressBar.new('cog_upload', folders.length)
  folders.each do |folder|
    cog_file = File.join(options[:img_base_directory], folder, "#{folder}.cog.tab.txt")
    
    if !File.exist?(cog_file)
      log.warn "Unable to find COG file for folder #{folder}, so skipping. I tried #{cog_file}"
      next
    end
    
    
    CSV.foreach(cog_file, :col_sep => "\t", :headers => true) do |row|
      gene_id = row[0]
      cog_id = row[9]
      cog_description = row[10]
      
      # Create the COG entry if it doesn't already exist
      cog = Cog.where(:name => cog_id).first
      if cog.nil?
        cog = Cog.new(
        :name => cog_id,
        :description => cog_description
        ).create!
      end
      
      # Create the link between the COG identifier and the gene
      gene = Gene.where(:img_id => gene_id)
      if gene.nil?
        log.warn "Unexpectedly didn't find gene with identifier #{gene_id}, did you upload the genes table already?"
        next
      end
      GeneCog.new(
      :gene_id => gene.id,
      :cog_id => cog.id
      ).create!
    end
    progress.inc
  end
  progress.finish
end #end if running as a script