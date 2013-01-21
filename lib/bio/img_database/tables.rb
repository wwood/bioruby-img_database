module Bio
  module IMG
    module Database
      class Gene < Connection
        has_many :cogs, :foreign_key => 'gene_oid', :primary_key => 'gene_oid'
        has_many :pfams, :foreign_key => 'gene_oid', :primary_key => 'gene_oid'
        has_many :tigrfams, :foreign_key => 'gene_oid', :primary_key => 'gene_oid'
        has_many :kos, :foreign_key => 'gene_oid', :primary_key => 'gene_oid'
      end
      
      class Cog < Connection
        belongs_to :gene, :foreign_key => 'gene_oid', :primary_key => 'gene_oid'
      end
      
      class Pfam < Connection
        belongs_to :gene, :foreign_key => 'gene_oid', :primary_key => 'gene_oid'
      end
      
      class Tigrfam < Connection
        belongs_to :gene, :foreign_key => 'gene_oid', :primary_key => 'gene_oid'
      end
      
      class Ko < Connection
        belongs_to :gene, :foreign_key => 'gene_oid', :primary_key => 'gene_oid'
      end
    end
  end
end
