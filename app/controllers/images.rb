class Images < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
  
  attr :libraryPath # "/users/georgeadamson/sites/steppes2/public/imageLibrary/"

  def index
    @images = Image.all
    display @images
  end

  def show(id)

    only_provides :jpg

    format = params[:format] || 'jpg'
    folder = CRM[:images_folder_path].gsub('\\','/')

    # Try to find images by ID or by filename:
    @image = Image.get(id) || Image.first_or_new( :path => "#{ id.gsub('+',' ') }.#{ format }" )
    raise NotFound unless @image && !@image.path.blank? && File.exist?( folder / @image.path )

    path = folder / @image.path
    send_file( path, :kind => 'image/jpeg', :disposition => 'inline' )
    #display @image, :layout => false

  end

  def new
    only_provides :html
    @libraryPath = "/users/georgeadamson/sites/steppes2/public/imageLibrary/"
    @company = Company.get(1)
    @currentFolder = @company.images_folder || "S*"
    @currentSubFolder = params[:folder_name] || "A*"
    @folder = Folder.new( @libraryPath / @currentFolder, @libraryPath / @currentFolder / @currentSubFolder )
    #@folderName = params[:folder_name] || "A*"
    @image = Image.new
    display @image
  end

  def edit(id)
    only_provides :html
    @image = Image.get(id)
    raise NotFound unless @image
    display @image
  end

  def create(image)
    @image = Image.new(image)
    if @image.save
      redirect resource(@image), :message => {:notice => "Image was successfully created"}
    else
      message[:error] = "Image failed to be created"
      render :new
    end
  end

  def update(id, image)
    @image = Image.get(id)
    raise NotFound unless @image
    if @image.update_attributes(image)
       redirect resource(@image)
    else
      display @image, :edit
    end
  end

  def destroy(id)
    @image = Image.get(id)
    raise NotFound unless @image
    if @image.destroy
      redirect resource(:images)
    else
      raise InternalServerError
    end
  end

end # Images
