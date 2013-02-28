class VirtualCabinet
  #include DataMapper::Resource

  # This generates a VirtualCabinet Command File in the folder corresponding to the specified user.
  # VirtualCabinet watches for file changes and will open the Client's docs in VirtualCabinet on the User's PC.

  # This method is named "create" simply to be consistent with datamapper:
  def self.create( user_id, client_id, trip_id = nil )

    sql_statement = 'EXEC sp_vcab_command_file @username=?, @client_id=?, @trip_id=?'

    result = repository(:default).adapter.select( sql_statement, user_id, client_id, trip_id )

  end

  class << self 
    alias :open :create
  end

end
