class MoneyIns < Application
  # provides :xml, :yaml, :js

  # IMPORTANT: MoneyIn AKA Invoice

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
  
  def index
    @money_ins = MoneyIn.all
    display @money_ins
  end

  def show(id)
    @money_in = MoneyIn.get(id)
    raise NotFound unless @money_in
    display @money_in
  end

  def new
    only_provides :html

    @trip = Trip.get( params[:trip_id] )

    message[:error] ||= ''
    message[:error] << "\n Before invoicing, the numbers of adults, children &amp; infants must match clients on this trip." if @trip && @trip.travellers != @trip.clients.length
    message[:error] << "\n No destinations have been provided for this trip. Please choose at least one country before attempting to create an invoice." if @trip && @trip.countries.empty?

    money_in = {
      :trip_id    => params[:trip_id],
      :client_id  => params[:client_id]
    }

    @money_in = MoneyIn.new(money_in)
    display @money_in

  end

  def edit(id) # UNUSED?
    only_provides :html
    @money_in = MoneyIn.get(id)
    raise NotFound unless @money_in
    display @money_in
  end

  def create(money_in)

    money_in[:trip_id]   ||= params[:trip_id]
    money_in[:client_id] ||= params[:client_id]

    @money_in = MoneyIn.new(money_in)
    @money_in.generate_doc_later = true

    #if @money_in.save || @money_in.save # HACK: Save may succeed but something is preventing it from returning true first time! (GA 07 Oct 2011)
    if @money_in.save
      
      message[:notice] = "Invoice record was created successfully"

      if @money_in.generate_doc_later

        @money_in.generate_doc_later = false
        run_later do
          @money_in.generate_doc()
        end

        message[:notice] << "\nThe document is being generated. It will appear on the documents page shortly"
        
      end

      #if request.ajax?
        render :new
      #else
      #  redirect resource( @money_in.client, @money_in.trip, :money_ins, :new ), :message => message
      #end

    else
      #collect_error_messages_for @money_in, :clients
			message[:error] = error_messages_for( @money_in, :header => 'The invoice record could not be created because:' )
      display @money_in, :new
    end

  end

  def update(id, money_in) # UNUSED?
    @money_in = MoneyIn.get(id)
    raise NotFound unless @money_in
    if @money_in.update(money_in)
       redirect resource(@money_in)
    else
      display @money_in, :edit
    end
  end

  def destroy(id)
    @money_in = MoneyIn.get(id)
    raise NotFound unless @money_in
    if @money_in.destroy
      redirect resource(:money_ins)
    else
      raise InternalServerError
    end
  end

end # MoneyIns
