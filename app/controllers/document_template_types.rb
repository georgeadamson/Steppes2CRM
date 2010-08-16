class DocumentTemplateTypes < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
  
  def index
    @document_template_types = DocumentTemplateType.all
    display @document_template_types
  end

  def show(id)
    @document_template_type = DocumentTemplateType.get(id)
    raise NotFound unless @document_template_type
    display @document_template_type
  end

  def new
    only_provides :html
    @document_template_type = DocumentTemplateType.new
    display @document_template_type
  end

  def edit(id)
    only_provides :html
    @document_template_type = DocumentTemplateType.get(id)
    raise NotFound unless @document_template_type
    display @document_template_type
  end

  def create(document_template_type)
    @document_template_type = DocumentTemplateType.new(document_template_type)
    if @document_template_type.save
      redirect resource(@document_template_type), :message => {:notice => "DocumentTemplateType was successfully created"}
    else
      message[:error] = "DocumentTemplateType failed to be created"
      render :new
    end
  end

  def update(id, document_template_type)
    @document_template_type = DocumentTemplateType.get(id)
    raise NotFound unless @document_template_type
    if @document_template_type.update(document_template_type)
       redirect resource(@document_template_type)
    else
      display @document_template_type, :edit
    end
  end

  def destroy(id)
    @document_template_type = DocumentTemplateType.get(id)
    raise NotFound unless @document_template_type
    if @document_template_type.destroy
      redirect resource(:document_template_types)
    else
      raise InternalServerError
    end
  end

end # DocumentTemplateTypes
