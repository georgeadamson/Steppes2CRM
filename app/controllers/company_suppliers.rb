class CompanySuppliers < Application
  # provides :xml, :yaml, :js
	
	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
  
  def index
    @company_suppliers = CompanySupplier.all
    display @company_suppliers
  end

  def show(id)
    @company_supplier = CompanySupplier.get(id)
    raise NotFound unless @company_supplier
    display @company_supplier
  end

  def new
    only_provides :html
    @company_supplier = CompanySupplier.new
    display @company_supplier
  end

  def edit(id)
    only_provides :html
    @company_supplier = CompanySupplier.get(id)
    raise NotFound unless @company_supplier
    display @company_supplier
  end

  def create(company_supplier)
    @company_supplier = CompanySupplier.new(company_supplier)
    if @company_supplier.save
      redirect resource(@company_supplier), :message => {:notice => "CompanySupplier was successfully created"}
    else
      message[:error] = "CompanySupplier failed to be created"
      render :new
    end
  end

  def update(id, company_supplier)
    @company_supplier = CompanySupplier.get(id)
    raise NotFound unless @company_supplier
    if @company_supplier.update(company_supplier)
       redirect resource(@company_supplier)
    else
      display @company_supplier, :edit
    end
  end

  def destroy(id)
    @company_supplier = CompanySupplier.get(id)
    raise NotFound unless @company_supplier
    if @company_supplier.destroy
      redirect resource(:company_suppliers)
    else
      raise InternalServerError
    end
  end

end # CompanySuppliers
