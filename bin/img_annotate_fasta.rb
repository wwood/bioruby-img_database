#!/usr/bin/env ruby

require 'optparse'
require 'bio-logger'
require 'csv'
require 'progressbar'
require 'bio'

$:.push File.join(File.dirname(__FILE__),'..','..','bioruby-taxonomy_definition_files','lib')
require 'bio-taxonomy_definition_files' #has IMG taxonomy parser file

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'bio-img_database'

if __FILE__ == $0 #needs to be removed if this script is distributed as part of a rubygem
  SCRIPT_NAME = File.basename(__FILE__); LOG_NAME = 'bio-img_database'

  # Parse command line options into the options hash
  options = {
    :logger => 'stderr',
  }
  o = OptionParser.new do |opts|
    opts.banner = "
      Usage: #{SCRIPT_NAME} -d <img_database.sqlite3> <gene_ids_file.txt>

      Given a list of IMG gene identifiers, output descriptions for each of them

      Example usage:
      $ img_annotate_fasta.rb -b my_blast_against_img.outfmt6.csv -d /srv/db/img/4.0/sqlite3/img4.0.sqlite3 -m /srv/db/img/4.0/metadata/img_metadata_4_0_FIXED.csv -f my.fasta >annotated.fasta\n"

    opts.separator "\nRequired arguments:\n\n"
    opts.on("-d", "--img-database IMG_DATABASE", "sqlite3 file that contains the data [required]") do |arg|
      options[:database_file] =  arg
    end
    opts.on("-m", "--img-metadata-file IMG_METADATA_FILENAME", "metadata file that includes the mapping from taxon identifier to taxonomic classifications [required]") do |arg|
      options[:img_metadata_file] =  arg
    end
    opts.on("-f", "--fasta FILE", "Annotate this fasta file, and output that rather than the annotations [required]") do |arg|
      options[:fasta_file] =  arg
    end
    opts.on("-b", "--blast-file FILE", "Blast output from -outfmt 6 against IMG genomes [required]") do |arg|
      options[:blast_file] =  arg
    end


    # logger options
    opts.separator "\nVerbosity:\n\n"
    opts.on("-q", "--quiet", "Run quietly, set logging to ERROR level [default INFO]") {Bio::Log::CLI.trace('error')}
    opts.on("--logger filename",String,"Log to file [default #{options[:logger]}]") { |name| options[:logger] = name}
    opts.on("--trace options",String,"Set log level [default INFO]. e.g. '--trace debug' to set logging level to DEBUG"){|s| Bio::Log::CLI.trace(s)}
  end; o.parse!
  if ARGV.length > 1 or options[:database_file].nil? or options[:img_metadata_file].nil? or options[:fasta_file].nil? or options[:blast_file].nil?
    $stderr.puts o
    exit 1
  end
  # Setup logging. bio-logger defaults to STDERR not STDOUT, I disagree
  Bio::Log::CLI.logger(options[:logger]); log = Bio::Log::LoggerPlus.new(LOG_NAME); Bio::Log::CLI.configure(LOG_NAME)

  # Connect to the database
  Bio::IMG::Database.connect options[:database_file]
  log.info "Successfully connected to the IMG database #{options[:database_file]}"

  # Read in the taxonomy file
  taxonomies = Bio::IMG::TaxonomyDefinitionFile.read(options[:img_metadata_file])
  raise unless taxonomies.length > 1000
  log.info "Read in #{taxonomies.length} different taxonomy entries"

  name_to_desc = {}
  log.info "Reading in blast results"
  progress = ProgressBar.new('blast_read',`wc -l #{options[:blast_file].inspect} |awk '{print $1}'`.to_i)
  CSV.foreach(options[:blast_file], :col_sep => "\t") do |row|
    the_id = row[1]
    unless the_id.match(/^\d+$/)
      log.warn "Skipping identifier #{the_id} as it doesn't contain all numbers (so isn't a IMG gene identifier in my book)"
      next
    end

    gene = Bio::IMG::Database::Gene.where(:img_id => the_id).first
    if gene.nil?
      log.warn "Identifier #{the_id} not found in the database. Hmm."
    else
      desc = gene.description.match(/^\d+ (.+?) \[/)[1]

      taxons = taxonomies.select{|t| t.taxon_id==gene.taxon_id}
      unless taxons.length == 1
        log.error "Incorrect number of taxons found for #{gene.taxon_id}. Strange."
      end
      taxon = taxons[0].genus_species

      desc = "#{taxon} #{desc}".gsub(/[^a-zA-Z01-9_]/,'_')#probably better ways to do this cleaning

      name_to_desc[row[0]] ||= desc
    end
    progress.inc
  end
  progress.finish
  log.info "Read in #{name_to_desc.length} blast based annotations"

  # Annotate the fasta file
  annotated_count = 0
  non_annotated_count = 0
  Bio::FlatFile.foreach(options[:fasta_file]) do |seq|
    firstname = seq.definition.gsub(/\s.*/,'')
    if name_to_desc[firstname]
      annotated_count += 1
      puts ">#{firstname} #{name_to_desc[firstname]}"
    else
      non_annotated_count += 1
      puts ">#{firstname}"
    end
    puts seq.seq
  end
  log.info "Output #{annotated_count} annotated genes and #{non_annotated_count} unannotated ones"
end #end if running as a script
