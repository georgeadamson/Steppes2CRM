class Photos < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
  
  attr :libraryPath # "/users/georgeadamson/sites/steppes2/public/imageLibrary/"
  before :find_country

  def index
    @photos = Photo.all
    display @photos

    if request.ajax? || params[:list]

      initFolderData()
      @photo = Photo.new
      #@test = "not-xmlhttp"
      #@test = "YAY!" if headers["X-Requested-With"] == "XMLHttpRequest"
      if params[:list] == "folders"
        partial 'photos/folders', :folder => @folder
      else  #if params[:list] == "files"
        partial 'photos/files', :folder => @folder
      end

    else
      display @photos
    end
  end

  def show(id)
    @photo = Photo.get(id)
    raise NotFound unless @photo
    if request.ajax?
      display @photo, :layout=>false
    else
      display @photo
    end
  end

  def new
    only_provides :html
    @photo = Photo.new
    initFolderData()
    if request.ajax?
      display @photo, :layout=>false
    else
      display @photo
    end
  end

  def edit(id)
    only_provides :html
    @photo = Photo.get(id)
    initFolderData()
    raise NotFound unless @photo
    display @photo, :layout=>!request.ajax?
  end

  def create(photo)
    @photo = Photo.new(photo)
    initFolderData()
    #@photo.path = "test!"
    if @photo.save
      redirect resource(:photos), :message => {:notice => "Photo was successfully created"}
    else
      message[:error] = "Photo failed to be created"
      #render :new
    end
  end

  def update(id, photo)
    @photo = Photo.get(id)
    initFolderData()
    raise NotFound unless @photo
    if @photo.update_attributes(photo)
       #redirect resource(@photo)
       display partial( "photos/thumbnail", photo=>@photo )
    else
      display @photo, :edit
    end
  end

  def destroy(id)
    @photo = Photo.get(id)
    raise NotFound unless @photo
    if @photo.destroy
      redirect resource(:photos)
    else
      raise InternalServerError
    end
  end


private

  def find_country
    (@country ||= Country.get(params[:country_id])) if params[:country_id]
  end

  def initFolderData
 
    @libraryPath = "/users/georgeadamson/sites/steppes2/public/imageLibrary/"
    @company = Company.get(1) # TODO: Use Session Company
    companyFolder = @company.imagesFolder || "S*"
    destinationFolder = params[:folder] || "A*" # AKA Country folder
    @folder = Folder.new( @libraryPath / companyFolder / destinationFolder, @libraryPath / companyFolder )
 
    unless @photo.nil?
      #@photo.countryPhotos.first.id = params[:countryId]
      #@photo.tags = (@photo.tags + "," + params[:tags]).split(",").uniq.delete_if{|s| s.strip=="" }.join(",") if params[:tags]
      @photo.tags = tagList(@photo.tags, params[:tags])
      @photo.companyFolder ||= companyFolder
      @photo.destinationFolder ||= destinationFolder
      @photo.path = @photo.companyFolder / @photo.destinationFolder / (@photo.path || "")
      Merb.logger.info! "@photo.path = #{@photo.path}"
    end

  end

end # Photos
