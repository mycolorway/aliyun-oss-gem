# coding: utf-8 

require 'digest/hmac'
require 'digest/md5'
require "rest-client"
require 'base64'
require 'multi_xml'

module AliyunOss

  class Api 
    def initialize(host, access_key_id, access_key_secret, opt={} )
      @host = host
      @access_key_id = access_key_id
      @access_key_secret = access_key_secret 
      @trace = opt[:trace] || false 
    end
    
    def create_bucket
    end

    def list_buckets 
      method = 'GET'
      bucket = ''
      object = ''
      body = ''
      headers = {}
      params = {}
      out = []
      res = http_request(method, bucket, object, headers, body, params)
      if res.code == 200 
        arr = MultiXml.parse res 
        arr["ListAllMyBucketsResult"]["Buckets"]["Bucket"].each do |m|
          out << m["Name"]
        end 
      end 
      out 
    end

    def get_bucket
    end 

    def delete_bucket
    end  

    def get_bucket_acl(bucket)
      method = 'GET'
      object = ''
      headers = {}
      body = ''
      params = {}
      params['acl'] = ''
      out = []
      begin 
        res = http_request(method, bucket, object, headers, body, params)
        if res.code == 200 
          arr = MultiXml.parse res 
          logger.info arr 
          #arr["ListAllMyBucketsResult"]["Buckets"]["Bucket"].each do |m|
          #  out << m["Name"]
          #end 
        end 
      rescue => ex 
        logger.info ex.message 
      end 

      out 
    end 

    def get_bucket_location 
    end





    def head_object(bucket, object, headers=nil )
      method = 'HEAD'
      body = ''
      params = {}
      begin 
        res = http_request(method, bucket, object, headers, body, params)
        return res.headers
      rescue => ex 
        logger.warn ex.message 
        return nil 
      end 
    end 

    def get_object(bucket, object, headers=nil )
      # 先获取头信息，判断文件大小 
      info = head_object(bucket, object) 
      if not info 
        raise "#{object} NOT Find "
      end 

      filesize = info[:content_length].to_i  
      if filesize > 1024*1024*4    # 4M  以上的文件建议采用 get_object_to_file 接口 
        logger.info "The file is more then 4M, please use Api get_object_to_file " 
        return nil  
      end 
      method = 'GET'
      body = ''
      params = {}
      res = http_request(method, bucket, object, headers, body, params)
      res.body 
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

    # 返回 oss的 签名路径 
    def sign_url(bucket, object, timeout=60, headers={}, params={}, filename="", browser="")
      # 注意 Content-Disposition值可以有以下几种编码格式
      # 1. 直接urlencode：     attachment; filename="struts2.0%E4%B8%AD%E6%96%87%E6%95%99%E7%A8%8B.chm"
      # 2. Base64编码：        attachment; filename="=?UTF8?B?c3RydXRzMi4w5Lit5paH5pWZ56iLLmNobQ==?="
      # 3. RFC2231规定的标准   attachment; filename*=UTF-8''%E5%9B%9E%E6%89%A7.msg
      # 4. 直接ISO编码的文件名 attachment;filename="测试.txt"
      # IE浏览器，采用URLEncoder编码
      # Opera浏览器，采用filename*方式
      # Safari浏览器，采用ISO编码的中文输出
      # Chrome浏览器，采用Base64编码或ISO编码的中文输出，测试发现也支持 filename*
      # FireFox浏览器，采用Base64或filename*或ISO编码的中文输出
      content_disposition = ""
      # Safari  Chrome  Firefox Opera  IE
      if not browser.empty?
        case browser 
        when "Chrome"
          content_disposition = "attachment;filename=\"#{filename}\""   #iso
        when "Firefox"
          content_disposition = "attachment;filename=\"#{filename}\""   #iso
        when "Safari"
          content_disposition = "attachment;filename=\"#{filename}\""   #iso
        when "Internet Explorer"
          content_disposition = "attachment;filename=\"#{URI.escape filename}\""  #urlencode
        when "Opera"
          content_disposition = "attachment;filename*=UTF-8''#{URI.escape filename}" # filename*
        else
          content_disposition = "attachment;filename=\"#{filename}\""
        end
      end 

      params['response-content-disposition'] = content_disposition if not content_disposition.empty? 

      object = object.encode('utf-8')
      resource = "/#{bucket}/#{object}#{get_resource(params)}"

      headers['Date'] = (Time.now.to_i + timeout).to_s

      params["OSSAccessKeyId"] = @access_key_id
      params["Expires"] = headers['Date']
      params["Signature"] = create_sign_for_normal_auth("GET", headers, resource, {:is_sign_url => true})

      url = "https://#{bucket}.#{@host}/#{object}"

      sign_url = append_param(url, params)
      return sign_url

    end 


    private 

    def logger 
      AliyunOss.logger(@trace) 
    end


    def gmtdate
      Time.now.gmtime.strftime("%a, %d %b %Y %H:%M:%S GMT")
    end



    def create_sign_for_normal_auth(method, headers, resource, p={} ) 
      content_md5 = ''
      content_type = ''
      date = headers['Date'] 
      

      canonicalized_oss_headers = ''
      canonicalized_resource = resource     # 这个要注意 要带 bucket

      string_to_sign = "#{method}\n#{content_md5}\n#{content_type}\n#{date}\n#{canonicalized_oss_headers}#{canonicalized_resource}"
      logger.info string_to_sign 

      digest = OpenSSL::Digest::SHA1.new
      h = OpenSSL::HMAC.digest(digest, @access_key_secret, string_to_sign)
      h = Base64.encode64(h).strip
      auth = "OSS #{@access_key_id}:#{h}"
      if p and p[:is_sign_url]
        auth = h 
      end 

      logger.info auth 
      return auth 
    end 


    def http_request(method, bucket, object, headers, body, params)
      tmp_bucket = bucket
      tmp_object = object

      tmp_headers = {}
      tmp_headers.merge! headers if headers

      tmp_params = {}
      tmp_params.merge! params

      res = http_request_with_redirect(method, tmp_bucket, tmp_object, tmp_headers, body, tmp_params)

      return res 
    end

    def http_request_with_redirect(method, bucket, object, headers={}, body='', params={})  
      object = object.encode('utf-8') 

      if bucket.empty? 
        resource = "/"
        headers['Host'] = @host
      else
        resource = "/#{bucket}/"  
        headers['Host'] = "#{bucket}.#{@host}" 
      end 

      resource = "#{resource.encode('utf-8')}#{object}#{get_resource(params)}"
      object = URI.escape object
      url = "/#{object}"
      url = append_param url, params
      
      headers['Date'] = gmtdate
      headers['Authorization'] = create_sign_for_normal_auth(method, headers, resource)
      

      fullurl = "#{headers['Host']}#{url}"
      logger.info "headers is #{headers} , url is #{fullurl} "
      res = RestClient.get(fullurl, headers) if method == "GET"
      res = RestClient.post(fullurl, headers) if method == "POST"
      res = RestClient.head(fullurl, headers) if method == "HEAD"
      res = RestClient.delete(fullurl, headers) if method == "DELETE"
      res = RestClient.put(fullurl, headers) if method == "PUT"
      logger.info res 

      res 
    end 



    def get_resource(params)
      if not params
        return ""
      end

      tmp_headers = {}
      params.each do |k,v|
        tmp_k = k.downcase.strip()
        tmp_headers[tmp_k] = v
      end
 
      override_response_list = ['response-content-type', 'response-content-language', \
				 'response-cache-control', 'logging', 'response-content-encoding', \
				 'acl', 'uploadId', 'uploads', 'partNumber', 'group', \
				 'delete', 'website', 'location', 'objectInfo', \
				 'response-expires', 'response-content-disposition']

      override_response_list.sort!
				 
      resource = ""
      separator = "?"
      override_response_list.each do |i|
        if tmp_headers.has_key? i.downcase
          resource << separator
          resource << i
          tmp_key = tmp_headers[i.downcase()]
          
          if not tmp_key.empty? then
            resource << "="
            resource << tmp_key
          end
          separator = "&"
        end
      end
      resource
    end


    def append_param(url, params)
      l = []
      params.each do |k,v|
        k = k.gsub('_', '-')
        if k == 'maxkeys'
          k = 'max-keys'
        end 
        
        v = v.encode('utf-8') if v 
        #URI.escape
        if v and not v.empty?
          l << "#{CGI::escape k}=#{CGI::escape v}"
        elsif k == 'acl'
          l << "#{CGI::escape k}"
        elsif not v or v.empty?
          l << "#{CGI::escape k}"
        end
      end 
      if l.size > 0 
        url = url + '?' + l.join("&")
      end 
      return url
    end 


  end 

end
