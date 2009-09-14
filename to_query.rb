class Object
  # Alias of <tt>to_s</tt>.                                                                                                                                                                             
  def to_param
    to_s
  end

  # Converts an object into a string suitable for use as a URL query string, using the given <tt>key</tt> as the                                                                                        
  # param name.                                                                                                                                                                                         
  #                                                                                                                                                                                                     
  # Note: This method is defined as a default implementation for all Objects for Hash#to_query to work.                                                                                                 
  def to_query(key)
    "#{CGI.escape(key.to_s)}=#{CGI.escape(to_param.to_s)}"
  end
end unless Object.new.respond_to? :to_query

class Hash
  # Converts a hash into a string suitable for use as a URL query string. An optional <tt>namespace</tt> can be                                                                                   
  # passed to enclose the param names (see example below).                                                                                                                                        
  #                                                                                                                                                                                               
  # ==== Example:                                                                                                                                                                                 
  #   { :name => 'David', :nationality => 'Danish' }.to_query # => "name=David&nationality=Danish"                                                                                                
  #                                                                                                                                                                                               
  #   { :name => 'David', :nationality => 'Danish' }.to_query('user') # => "user%5Bname%5D=David&user%5Bnationality%5D=Danish"                                                                    
  def to_query(namespace = nil)
    collect do |key, value|
      value.to_query(namespace ? "#{namespace}[#{key}]" : key)
    end.sort * '&'
  end
end unless Hash.new.respond_to? :to_query
