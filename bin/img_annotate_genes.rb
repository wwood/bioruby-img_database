#!/usr/bin/env ruby

require 'optparse'
require 'bio-logger'
require 'bio-img_metadata'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'bio-img_database'

include Bio::IMG::Database

SCRIPT_NAME = File.basename(__FILE__); LOG_NAME = SCRIPT_NAME.gsub('.rb','')

# Parse command line options into the options hash
options = {
  :logger => 'stderr',
  :database_path => File.expand_path('../../db/development.sqlite3', __FILE__),
  :input_is_blastp => false,
}
o = OptionParser.new do |opts|
  opts.banner = "
    Usage: #{SCRIPT_NAME} <arguments>

    Annotate genes with data from a local IMG database\n\n"

  opts.on("-m", "--img-metadata-file IMG_METADATA_FILENAME", "metadata file that includes the mapping from taxon identifier to taxonomic classifications [required]") do |arg|
    options[:img_metadata_file] =  arg
  end
  opts.on("-d", "--img-database ARG", "path to the database [default: #{options[:database_path]}]") do |arg|
    options[:database_path] = arg
  end
  opts.on("-b", "--blastp-input", "input is a blast csv (-outfmt 6 on BLAST+, where the -db was IMG) output file [default: #{options[:input_is_blastp]}]") do |arg|
    options[:input_is_blastp] = true
  end


  # logger options
  opts.separator "\nVerbosity:\n\n"
  opts.on("-q", "--quiet", "Run quietly, set logging to ERROR level [default INFO]") {Bio::Log::CLI.trace('error')}
  opts.on("--logger filename",String,"Log to file [default #{options[:logger]}]") { |name| options[:logger] = name}
  opts.on("--trace options",String,"Set log level [default INFO]. e.g. '--trace debug' to set logging level to DEBUG"){|s| Bio::Log::CLI.trace(s)}
end; o.parse!
if ARGV.length > 1 or options[:img_metadata_file].nil?
  $stderr.puts o
  exit 1
end
# Setup logging. bio-logger defaults to STDERR not STDOUT, I disagree
Bio::Log::CLI.logger(options[:logger]); log = Bio::Log::LoggerPlus.new(LOG_NAME); Bio::Log::CLI.configure(LOG_NAME)

# Connect to the database
Bio::IMG::Database.connect options[:database_path]
log.info "Successfully connected to the IMG database #{options[:database_path]}"

# Read in the taxonomy file
taxonomies = Bio::IMG::TaxonomyDefinitionFile.read(options[:img_metadata_file])
taxonomy_hash = {}
taxonomies.each do |taxon|
  raise "Duplicate taxon ID in taxonomy file! #{taxon.taxon_id}" if taxonomy_hash.key?(taxon.taxon_id)
  taxonomy_hash[taxon.taxon_id] = taxon
end
raise unless taxonomies.length > 1000
log.info "Read in #{taxonomies.length} different taxonomy entries"

# For each gene, annotate
ARGF.each_line do |line|
  gene_id = nil
  to_print = []

  if options[:input_is_blastp]
    splits = line.split("\t")
    unless splits.length == 12
      log.error "Unexpected number of fields found in BLAST output file (#{splits.length}): #{line}"
      exit 1
    end
    gene_id = splits[1]
    query_id = splits[0]
    perc_id = splits[2]
    evalue = splits[10]
    alignment_length = splits[3]

    to_print.push query_id
    to_print.push perc_id
    to_print.push evalue
    to_print.push alignment_length
  else
    gene_id = line.strip
  end

  to_print.push gene_id

  cogs = Cog.where(:gene_oid => gene_id.to_i)
  if cogs.length >= 1
    if cogs.length > 1
      # I don't think this should happe, but just to be paranoid
      log.warn "Found multiple COG annotations for gene ID #{gene_id}, only taking the first one"
    end

    cog = cogs[0]
    to_print.push cog.cog_id
    to_print.push cog.cog_name
    to_print.push cog.evalue

  elsif cogs.empty?
    3.times{to_print.push nil}
  end

  # Annotate with the annotation from the fasta file
  gene = Gene.where(:img_id => gene_id).first
  if gene
    to_print.push gene.description

    # Annotate with taxonomy
    taxon = taxonomy_hash[gene.taxon_id]
    if taxon.nil?
      log.error "Incorrect number of taxons found for taxonomy ID #{gene.taxon_id}, found from #{gene.img_id}. Strange. Skipping."
      7.times{to_print.push nil}
    else
      to_print.push taxon.domain
      to_print.push taxon.phylum
      to_print.push taxon.class_name
      to_print.push taxon.order
      to_print.push taxon.family
      to_print.push taxon.genus
      to_print.push taxon.species
    end
  else
    raise
  end

  puts to_print.join("\t")
end
