#!/usr/bin/env ruby

require 'optparse'
require 'bio-logger'

$:.push File.join(File.dirname(__FILE__),'..','..','bioruby-taxonomy_definition_files','lib')
require 'bio-taxonomy_definition_files' #has IMG taxonomy parser file

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'bio-img_database'

require 'bio-krona'
require 'progressbar'

if __FILE__ == $0 #needs to be removed if this script is distributed as part of a rubygem
  SCRIPT_NAME = File.basename(__FILE__); LOG_NAME = 'bio-img_database'
  
  # Parse command line options into the options hash
  options = {
    :logger => 'stderr',
  }
  o = OptionParser.new do |opts|
    opts.banner = "
      Usage: #{SCRIPT_NAME} -m <img_metadata_csv> -d <img_database.sqlite3> -k <overview.html> <img_gene_ids_file.txt>
      
      Given a list of IMG gene identifiers, output a krona diagram of the phylogenetic distribution of those hits. Input can be via a file specified as the first argument, or as STDIN.

      Example usage:
      $ awk '{print $2}' my_blast_against_img.outfmt6.csv |img_taxons_from_gene_ids.rb -m /srv/whitlam/bio/db/img/3.5/genomes/finished/scripts_and_metadata/IMG3.5_release_metadata.tsv -d /srv/whitlam/bio/db/img/3.5/taxon_gene_id_mapping_database/img_database.sqlite3 -k my_blast_taxonomy.html\n"
      
    opts.on("-m", "--img-metadata-file IMG_METADATA_FILENAME", "metadata file that includes the mapping from taxon identifier to taxonomic classifications [required]") do |arg|
      options[:img_metadata_file] =  arg
    end
    opts.on("-d", "--img-database IMG_DATABASE", "sqlite3 file that contains the data [required]") do |arg|
      options[:database_file] =  arg
    end
    opts.on("-k","--html OUTPUT_HTML_FILE", "Output filename of the Krona output file") do |arg|
      options[:krona_output_file] = arg
    end

    # logger options
    opts.separator "\nVerbosity:\n\n"
    opts.on("-q", "--quiet", "Run quietly, set logging to ERROR level [default INFO]") {Bio::Log::CLI.trace('error')}
    opts.on("--logger filename",String,"Log to file [default #{options[:logger]}]") { |name| options[:logger] = name}
    opts.on("--trace options",String,"Set log level [default INFO]. e.g. '--trace debug' to set logging level to DEBUG"){|s| Bio::Log::CLI.trace(s)}
  end; o.parse!
  if ARGV.length > 1 or options[:img_metadata_file].nil? or options[:database_file].nil? or options[:krona_output_file].nil?
    $stderr.puts o
    exit 1
  end
  # Setup logging. bio-logger defaults to STDERR not STDOUT, I disagree
  Bio::Log::CLI.logger(options[:logger]); log = Bio::Log::LoggerPlus.new(LOG_NAME); Bio::Log::CLI.configure(LOG_NAME)
  
  
  # Read in the taxonomy file
  taxonomies = Bio::IMG::TaxonomyDefinitionFile.read(options[:img_metadata_file])
  raise unless taxonomies.length > 1000
  log.info "Read in #{taxonomies.length} different taxonomy entries"
  
  # Connect to the database
  Bio::IMG::Database.connect options[:database_file]
  log.info "Successfully connected to the IMG database #{options[:database_file]}"
  
  krona_taxons = {}
  lines = ARGF.readlines
  progress = ProgressBar.new('taxonomy_finding', lines.length)
  
  lines.each do |line|
    the_id = line.strip
    unless the_id.match(/^\d+$/)
      log.warn "Skipping identifier #{the_id} as it doesn't contain all numbers (so isn't a IMG gene identifier in my book)"
      next
    end
    
    gene = Bio::IMG::Database::Gene.where(:img_id => the_id).first
    if gene.nil?
      log.warn "Identifier #{the_id} not found in the database. Hmm."
    else
      taxons = taxonomies.select{|t| t.taxon_id==gene.taxon_id}
      unless taxons.length == 1
        log.error "Incorrect number of taxons found for #{gene.taxon_id}. Strange."
      end
      taxon = taxons[0]
      
      taxon_for_krona = [
        taxon.domain,
        taxon.phylum,
        taxon.class_name,
        taxon.order,
        taxon.family,
        taxon.genus,
        taxon.species,
      ]
      krona_taxons[taxon_for_krona] ||= 0
      krona_taxons[taxon_for_krona] += 1
      # puts [
        # the_id,
        # taxon.taxon_id,
        # taxon.domain,
        # taxon.phylum,
        # taxon.class_name,
        # taxon.order,
        # taxon.family,
        # taxon.genus,
        # taxon.species,
      # ].join("\t")
    end
    progress.inc
  end
  #$stderr.puts krona_taxons.inspect
  progress.finish
  File.open(options[:krona_output_file],'w') do |out|
    out.puts Bio::Krona.html(krona_taxons)
  end
  log.info "Successfully wrote HTML to #{options[:krona_output_file]}"
end #end if running as a script
