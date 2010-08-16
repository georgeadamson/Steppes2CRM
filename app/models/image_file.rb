class ImageFile

  test = "hi"

  def initialize
    @libraryPath = "/users/georgeadamson/sites/steppes2/public/imageLibrary"
  end

  def currentFolder(folderName = "S*")
    @currentFolder = folderName
  end

  def url(filename = nil, companyId = 1)
    unless filename.nil?
      @filename = filename
      @company = Company.get(companyId)
      return "" / :imageLibrary / @company.imagesFolder / @filename
    else
      return "" / :images / "merb.jpg"  #TODO: Change default image!
    end
  end

  def folderList(parentFolder = "S*")
    # Return array of child folders in the parentFolder (defaults to folders beginning with "Steppes...")

    folder = @libraryPath / parentFolder

    # Fetch list of child folders: (The trailing slash ("*/") ensures we ignore files)
    folders = Dir[ folder / "*" / "" ].map{ |file| file.sub(folder,"").propercase }
    return folders

  end

  def fileList(parentFolder = "A*")
    # Return array of all files within parentFolder (Defaults to folders beginning with "A...")

    root = "/users/georgeadamson/sites/steppes2/public/imageLibrary/SteppesEast/_Photos"

    #return Dir.entries(folderPath).find_all{ |filename| filename =~ /.jpg$/ }.sort()
    return Dir[ root / parentFolder / "**" / "*.jpg" ].map{ |file| file.sub(root,"").propercase }
 
  end

  def folderCollection(companyId = 1)
    @company = Company.get(companyId)
    return { @company.name => folderList(@company.imagesFolder) }
  end

  def fileCollection(parentFolder = "A*")

    files = fileList(parentFolder)
    folders = files.map{ |file| File.dirname(file) }.uniq().sort()  # Deduplicated list of folder paths
    result = {}

    folders.each do |folder|
      subset = files.find_all{ |file| File.dirname(file) == folder }
      result[ folder ] = formatPathArray( subset ) unless subset.empty?
    end

    return result

  end

  # Convert simple array of paths to an array of [path,name] pairs:
  def formatPathArray(pathArray, fullPath = false)
    return pathArray.map{ |path| [ path, fullPath ? path : File.basename(path) ] }
  end

end
