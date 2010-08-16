class ImageFiles < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
  
  def index
    @image_files = ImageFile.all
    display @image_files
  end

  def show(id)
    @image_file = ImageFile.get(id)
    raise NotFound unless @image_file
    display @image_file
  end

  def new
    only_provides :html
    @image_file = ImageFile.new
    display @image_file
  end

  def edit(id)
    only_provides :html
    @image_file = ImageFile.get(id)
    raise NotFound unless @image_file
    display @image_file
  end

  def create(image_file)
    @image_file = ImageFile.new(image_file)
    if @image_file.save
      redirect resource(@image_file), :message => {:notice => "ImageFile was successfully created"}
    else
      message[:error] = "ImageFile failed to be created"
      render :new
    end
  end

  def update(id, image_file)
    @image_file = ImageFile.get(id)
    raise NotFound unless @image_file
    if @image_file.update_attributes(image_file)
       redirect resource(@image_file)
    else
      display @image_file, :edit
    end
  end

  def destroy(id)
    @image_file = ImageFile.get(id)
    raise NotFound unless @image_file
    if @image_file.destroy
      redirect resource(:image_files)
    else
      raise InternalServerError
    end
  end

end # ImageFiles
