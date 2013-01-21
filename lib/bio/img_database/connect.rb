module Bio
  module IMG
    module Database
      def self.connect(db_path=File.join(File.dirname(__FILE__),'..','..','..','db','development.sqlite3'))
        Connection.connect db_path
      end

      class Connection < ActiveRecord::Base
        self.abstract_class = true
        # Connect to a metadata database.
        def self.connect(db_path)
          log = Bio::Log::LoggerPlus['bio-img_database']
          log.info "Attempting to connect to database #{db_path}"

          # default:
          # adapter: sqlite3
          # database: db/SRAmetadb.sqlite
          # pool: 5
          # timeout: 5000

          options = {
            :adapter => 'sqlite3',
            :database => db_path,
            :pool => 5,
            :timeout => 5000,
          }

          establish_connection(options)
        end
      end
    end
  end
end
