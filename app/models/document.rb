class Document < ActiveRecord::Base
  
  attr_accessor :rdf, :calais_signature

  has_one  :full_text,  :dependent => :destroy
  has_many :pages,      :dependent => :destroy  
  has_many :metadata,   :dependent => :destroy
  
  validates_presence_of :organization_id, :account_id, :access, :page_count,
                        :title, :slug
                        
  before_validation_on_create :ensure_titled
  
  after_destroy :delete_assets
  
  SEARCHABLE_ATTRIBUTES = [:title, :source]
  
  delegate :text, :to => :full_text
  
  # Main document search method -- handles queries.
  def self.search(query, options={})
    query = DC::Search::Parser.new.parse(query) if query.is_a? String
    query.run
  end
  
  # Ex: docs/1011
  def path
    File.join('docs', id.to_s)
  end
  
  # Ex: docs/1011/sec-madoff-investigation.txt
  def full_text_path
    File.join(path, slug + '.txt')
  end
  
  # Ex: docs/1011/sec-madoff-investigation.pdf
  def pdf_path
    File.join(path, slug + '.pdf')
  end
  
  # Ex: docs/1011/sec-madoff-investigation.jpg
  def thumbnail_path
    File.join(path, slug + '.jpg')
  end
  
  # Ex: docs/1011/pages
  def pages_path
    File.join(path, 'pages')
  end
  
  def public?
    self.access == DC::Access::PUBLIC
  end
  
  def pdf_url
    File.join(DC::Store::AssetStore.web_root, pdf_path)              
  end
  
  def thumbnail_url
    File.join(DC::Store::AssetStore.web_root, thumbnail_path)
  end
  
  def full_text_url
    File.join(DC::Store::AssetStore.web_root, full_text_path)
  end
  
  def asset_store
    @asset_store ||= DC::Store::AssetStore.new
  end
  
  def save_assets(assets)
    asset_store.save(self, assets)
  end
  
  def delete_assets
    asset_store.destroy(self)
  end
  
  def to_json(options={})
    super(options.merge({:methods => [:pdf_url, :thumbnail_url, :full_text_url]}))
  end
  
  
  private
  
  def ensure_titled
    self.title ||= "Untitled Document"
    return true if self.slug
    slugged = title.mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n, '').to_s # As ASCII
    slugged.gsub!(/[']+/, '') # Remove all apostrophes.    
    slugged.gsub!(/\W+/, ' ') # All non-word characters become spaces.   
    slugged.strip!            # strip surrounding whitespace
    slugged.downcase!         # ensure lowercase
    slugged.gsub!(' ', '-')   # dasherize spaces
    self.slug = slugged
  end
  
end