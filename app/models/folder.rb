
# mount -t smbfs //george@selfs01/images /users/georgeadamson/sites/steppes2/public/imageLibrary
# umount -a -t smbfs

class Folder

  attr :parentFolder
  attr :currentFolder

  def initialize(folder = nil, parentFolder = nil)
    @currentFolder = folder || CRM[:images_folder_path] || "/users/georgeadamson/sites/steppes2/public/imageLibrary/S*/A*"
    @parentFolder  = parentFolder || File.dirname(@currentFolder)
  end

  # Return array of child folders in the parentFolder (defaults to folders beginning with "Steppes...")
  def all(match = "*", formatCollection = false, parentFolder = nil, fullPath = false)

    @parentFolder = parentFolder || @parentFolder

    # Fetch list of child folders: (The trailing slash ("*/") ensures we ignore files)
    query = @parentFolder / match / ""
    folders = Dir[query]
    @currentFolder ||= folders.first
    folders.map!{ |file| file.sub(@parentFolder,"").gsub(/^\/|\/$/,"") } unless fullPath
    folders.map!{ |file| file.propercase }

    return formatCollection ? folders : formatPathCollection( folders.sort(), fullPath )

  end

  # Return array of all files within parentFolder (Defaults to folders beginning with "S...")
  def files(match = '*.jpg', formatCollection = true, folder = nil, recursive = true, fullPaths = false)

    #root = "/users/georgeadamson/sites/steppes2/public/imageLibrary/SteppesEast/_Photos"
    @currentFolder ||= folder
    query = @currentFolder.gsub('\\','/') / '**' / match

    #return Dir.entries(folderPath).find_all{ |filename| filename =~ /.jpg$/ }.sort()
    unwanted_path_string = @currentFolder.gsub('\\','/')
    files = Dir[query].map{ |file| file.sub(unwanted_path_string,'').sub(/^\//,'') }  #.propercase
 
    if formatCollection
      result = {}
      folders = files.map{ |file| File.dirname(file) }.uniq().sort()  # Deduplicated list of folder paths
  
      folders.each do |folder|
        subset = files.find_all{ |file| File.dirname(file) == folder }
        result[ folder ] = formatPathCollection( subset ) unless subset.empty?
      end
    else
      result = files
    end

    return result
  end

  def name
    return File.basename(@currentFolder).propercase
  end

  # Convert simple array of paths to an array of [path,name] pairs:
  def formatPathCollection(pathArray, fullPath = false)
    return pathArray.map{ |path| [ path, fullPath ? path : File.basename(path) ] }
  end

end
