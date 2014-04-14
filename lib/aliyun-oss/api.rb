# coding: utf-8 

module AliyunOss

  class Api 
    def initialize(host, access_key_id, access_key_secret, opt={} )
      @host = host
      @access_key_id = access_key_id
      @access_key_secret = access_key_secret 
    end
    
    def create_bucket
    end

    def list_bucket 
    end

    def get_bucket
    end 

    def delete_bucket
    end  

    def get_bucket_acl
    end 

    def get_bucket_location 
    end





    def head_object 
    end 

    def get_object 
    end 

    def get_object_info 
    end 

    def delete_object 
    end 

    def copy_object 
    end 

    def put_objct
    end 




    def delete_objects 
    end 

    def list_objects 
    end 




  end 

end