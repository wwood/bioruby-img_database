module Bio
  module IMG
    module Database
      class Gene < Connection
        has_many :cogs, :through => :genes_cogs
      end
      
      class Cog < Connection
        has_many :genes, :through => :genes_cogs
      end
      
      class GeneCog < Connection
        belongs_to :gene
        belongs_to :cog
      end
    end
  end
end
