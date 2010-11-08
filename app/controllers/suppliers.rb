class Suppliers < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }

  def index

		@suppliers = Supplier.all( :order => [:name] )
		@suppliers = @suppliers.all( :type_id => params[:type_id] ) if params[:type_id].to_i > 0

    display @suppliers
  end

  def show(id)
    @supplier = Supplier.get(id)
    raise NotFound unless @supplier
    display @supplier
  end

  def new
    only_provides :html
    @supplier = Supplier.new()
    @supplier.kind_id = params[:type_id] || 1
    display @supplier
  end

  def edit(id)
    only_provides :html
    @supplier = Supplier.get(id)
    raise NotFound unless @supplier
    display @supplier
  end

	def create(supplier)
		generic_action_create( supplier, Supplier, :collect_errors_for => [:companies] )
	end

	def update(id, supplier)
		generic_action_update( id, supplier, Supplier, :collect_errors_for => [:companies] )
	end

	def destroy(id)
		generic_action_destroy( id, Supplier )
	end

end # Suppliers
