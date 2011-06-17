class Suppliers < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }

  def index

    @supplier_type_id = session[:recent_supplier_type_id].to_i
    
		@suppliers = Supplier.all( :order => [:name], :limit => 10000 ) # TODO: Find a way to show less! (Eg: Of the ~9000 suppliers, approx ~900 begin with H)
		@suppliers = @suppliers.all( :type_id => @supplier_type_id ) if @supplier_type_id > 0

    display @suppliers
  end

  def show(id)
    @supplier = Supplier.get(id)
    raise NotFound unless @supplier
    display @supplier
  end

  def new
    @supplier_type_id = session[:recent_supplier_type_id] || 1
    only_provides :html
    @supplier = Supplier.new()
    @supplier.type_id = @supplier_type_id
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
