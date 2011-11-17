class Image
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String, :default=>"Photo" # Image "alt" text
  property :path, String, :default=>""
  property :resolution, String, :length=>1, :default=>"M"
  property :approved, Boolean, :default=>false
  property :web_guid, String, :default=>""
  property :tags, String, :length=>200, :default=>""

  belongs_to :country

  def initialize(*)
    super
    @libraryPath = "/users/georgeadamson/sites/steppes2/public/imageLibrary"
  end

  def urlFor(filename)
    @company = Company.get(1)
    return "" / :imageLibrary / @company.imagesFolder / filename
  end

  def getFolders(companyId = 1)

    @company = Company.get(companyId || 1)
    folder = @libraryPath / @company.imagesFolder

    # Fetch list of child folders: (The trailing slash ("*/") ensures we ignore files)
    folders = Dir[ folder / "*" / "" ].map{ |file| file.sub(folder,"").propercase }
    return { @company.name => formatPathArray( folders.sort() ) }

  end

  def getFiles(folderPath = "A*")

    root = "/users/georgeadamson/sites/steppes2/public/imageLibrary/SteppesEast/_Photos"

    files = Dir[ root / folderPath / "**" / "*.jpg" ].map{ |file| file.sub(root,"").propercase }
    folders = files.map{ |file| File.dirname(file) }.uniq().sort()  # Deduplicated list of folder paths
    result = {}

    folders.each do |folder|
      subset = files.find_all{ |file| File.dirname(file) == folder }
      result[ folder ] = formatPathArray( subset ) unless subset.empty?
    end

    #return Dir.entries(folderPath).find_all{ |filename| filename =~ /.jpg$/ }.sort()
    return result

  end

  # Convert simple array of paths to an array of [path,name] pairs:
  def formatPathArray(pathArray, fullPath = false)
    return pathArray.map{ |path| [ path, fullPath ? path : File.basename(path) ] }
  end

end

