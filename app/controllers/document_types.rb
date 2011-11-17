class DocumentTypes < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }

  def index
    @document_types = DocumentType.all
    display @document_types
  end

  def show(id)
    @document_type = DocumentType.get(id)
    raise NotFound unless @document_type
    display @document_type
  end

  def new
    only_provides :html
    @document_type = DocumentType.new
    display @document_type
  end

  def edit(id)
    only_provides :html
    @document_type = DocumentType.get(id)
    raise NotFound unless @document_type
    display @document_type
  end

  def create(document_type)
    generic_action_create( document_type, DocumentType )
  end

  def update(id, document_type)
    generic_action_update( id, document_type, DocumentType )
  end

  def destroy(id)
    generic_action_destroy( id, DocumentType )
  end

end # DocumentTypes
