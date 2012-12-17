#!/usr/bin/env ruby

require 'optparse'
require 'bio-logger'

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
      $ awk '{print $2}' my_blast_against_img.outfmt6.csv |img_gene_ids_to_descriptions.rb -d /srv/whitlam/bio/db/img/3.5/taxon_gene_id_mapping_database/img_database.sqlite3 >descriptions.csv\n"
      
    opts.separator "\nRequired arguments:\n\n"
    opts.on("-d", "--img-database IMG_DATABASE", "sqlite3 file that contains the data [required]") do |arg|
      options[:database_file] =  arg
    end
    opts.on("-m", "--img-metadata-file IMG_METADATA_FILENAME", "metadata file that includes the mapping from taxon identifier to taxonomic classifications [required]") do |arg|
      options[:img_metadata_file] =  arg
    end

    # logger options
    opts.separator "\nVerbosity:\n\n"
    opts.on("-q", "--quiet", "Run quietly, set logging to ERROR level [default INFO]") {Bio::Log::CLI.trace('error')}
    opts.on("--logger filename",String,"Log to file [default #{options[:logger]}]") { |name| options[:logger] = name}
    opts.on("--trace options",String,"Set log level [default INFO]. e.g. '--trace debug' to set logging level to DEBUG"){|s| Bio::Log::CLI.trace(s)}
  end; o.parse!
  if ARGV.length > 1 or options[:database_file].nil? or options[:img_metadata_file].nil?
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
  
  ARGF.each_line do |line|
    the_id = line.strip
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
      puts [
            the_id,
            desc,
           ].join("\t")
    end
  end
end #end if running as a script
