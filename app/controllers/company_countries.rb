class CompanyCountries < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
  
  def index
    @company_countries = CompanyCountry.all
    display @company_countries
  end

  def show(id)
    @company_country = CompanyCountry.get(id)
    raise NotFound unless @company_country
    display @company_country
  end

  def new
    only_provides :html
    @company_country = CompanyCountry.new
    display @company_country
  end

  def edit(id)
    only_provides :html
    @company_country = CompanyCountry.get(id)
    raise NotFound unless @company_country
    display @company_country
  end

  def create(company_country)
    @company_country = CompanyCountry.new(company_country)
    if @company_country.save
      redirect resource(@company_country), :message => {:notice => "CompanyCountry was successfully created"}
    else
      message[:error] = "CompanyCountry failed to be created"
      render :new
    end
  end

  def update(id, company_country)
    @company_country = CompanyCountry.get(id)
    raise NotFound unless @company_country
    if @company_country.update(company_country)
       redirect resource(@company_country)
    else
      display @company_country, :edit
    end
  end

  def destroy(id)
    @company_country = CompanyCountry.get(id)
    raise NotFound unless @company_country
    if @company_country.destroy
      redirect resource(:company_countries)
    else
      raise InternalServerError
    end
  end

end # CompanyCountries
