class DocumentTemplates < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }

  def index
    @document_templates = DocumentTemplate.all
    display @document_templates
  end

  def show(id)
    @document_template = DocumentTemplate.get(id)
    raise NotFound unless @document_template
    display @document_template
  end

  def new
    only_provides :html
    @document_template = DocumentTemplate.new
    display @document_template
  end

  def edit(id)
    only_provides :html
    @document_template = DocumentTemplate.get(id)
    raise NotFound unless @document_template
    display @document_template
  end

  def create(document_template)
    generic_action_create( document_template, DocumentTemplate )
  end

  def update(id, document_template)
    generic_action_update( id, document_template, DocumentTemplate )
  end

  def destroy(id)
    generic_action_destroy( id, DocumentTemplate )
  end

end # DocumentTemplates
