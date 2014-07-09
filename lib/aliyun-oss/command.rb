# coding: utf-8 

require 'optparse'

module AliyunOss

  class Command


    def initialize(args)
      @args = args
      @options = {}
      @current_dir = `pwd`    # 本地的当前目录 
      @current_bucket = "" # oss 的当前 bucket 
    end

    def run 
      @opts = OptionParser.new(&method(:set_opts))
      @opts.parse!(@args)
      process
    end

    private

    def set_opts(opts)

      opts.on('-H','--host HOST', 'host') do |v|
        @options[:host] = v 
      end
      opts.on('-i','--id ID', 'accessid') do |v|
        @options[:id] = v
      end
      opts.on('-k','--key KEY', 'accesskey') do |v|
        @options[:key] = v
      end
      opts.on('--trace', 'Show a full traceback on error') do
        @options[:trace] = true
      end


      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end

      opts.on_tail('-v', '--version', 'Print version') do
        puts "AliyunOss #{VERSION}"
        exit
      end
    end

    def process #进入命令行模式 ， 等待用户
      #puts @options
      oss = AliyunOss::Api.new(@options[:host], @options[:id], @options[:key], {:trace => @options[:trace]}) 
      
      while true
        cmd = input ">>"
        #puts cmd

        case cmd 
        when "help"
          puts [
            "ls             -- list location directory contents", 
            "cd [LOCATION]  -- change location work dir ", 
            "pwd",
            "osslist        -- list oss buckets", 
            "osscd BUCKET   -- change oss bucket", 
            #"ossls          -- ls objects of current bucket  ",
            "ossls OBJECT   -- get head info of current bucket object", 
            "osspwd         -- show current oss bucket",
            "ossget OBJECT  -- get oss object to location directory", 
            "ossurl OBJECT  -- get oss object web url ",
            "help",
            "exit"]
        when "exit"
          break
        when /^cd\s.*/
          cmd = "cd #{current_dir} && #{cmd} && pwd "
          @current_dir = `#{cmd} `.strip 
          puts @current_dir

        when "pwd"
          puts @current_dir 
          puts "oss://#{@current_bucket}" 

        when "ls"
          puts `ls -rlt #{current_dir} `

        when "osspwd"
          puts "oss://#{@current_bucket}" 
          puts @current_dir 

        when "osslist"
          b = oss.list_buckets
          puts b 

        when /^osscd\s.*/ 
          p = cmd.split(" ") 
          bucket = p[1] 
          if not bucket 
            puts "BUCKET is null "
          else
            bucket.strip! 
            bucket = ""    if bucket == ".." || bucket == "/"
            bucket = @current_bucket if bucket == "."
            oss.get_bucket_acl bucket # 获取一次bucket 当前访问权限，判断这个bucket 是否有效 
            @current_bucket = bucket 
          end 
          puts "oss://#{@current_bucket} "

        when /^ossls\s.*/
          p = cmd.split(" ") 
          obj = p[1] 
          if not obj 
            puts "OBJECT is null "
          else
            obj.strip! 
            # 返回 hash  
            # {:date=>"Tu GMT", :content_type=>"", :content_length=>"732", 
            #:connection=>"close", :accept_ranges=>"bytes", :etag=>", 
            #:last_modified=>"", :server=>"", :x_oss_request_id=>""}
            puts oss.head_object( current_bucket, obj)
          end 

        when /^ossget\s.*/
          p = cmd.split(" ") 
          obj = p[1] 
          if not obj 
            puts "OBJECT is null "
          else
            obj.strip! 
            begin 
              out = oss.get_object( current_bucket, obj) 
              local_path = File.join current_dir, obj 
              dirs = local_path[0, local_path.rindex("/")]
              FileUtils.mkdir_p dirs 

              if out  # 
                #将out 写入本地 current_dir 
                File.open(local_path, "w") { |f| f.write out }
                puts "Save Success to #{local_path} "
              else   # 文件可能超大  
                puts "#{obj} more then 4M , try "
                strwget =  " wget #{oss.sign_url(current_bucket, obj, 600).gsub('&',"\\\\&") } -O #{local_path}" 
                puts strwget 
                puts `#{strwget}` 
              end
            rescue => ex   # 对象不存在抛异常 
              puts ex.message 
            end 

          end 

        when /^ossurl\s.*/
          p = cmd.split(" ") 
          obj = p[1] 
          if not obj 
            puts "OBJECT is null "
          else
            obj.strip! 
            out = oss.sign_url( current_bucket, obj, 600) 
            puts out 
          end 

        else 
          puts "ERROR input"
        end 
      end
    end 


    def input(print_str)
      input = ""
      while input == ""
        print(print_str)
        input = STDIN.gets 
        # tab 自动补齐模式 
        input.chomp!
      end
      return input
    end

    def current_dir 
      @current_dir = @current_dir.strip if @current_dir
    end 

    def current_bucket 
      @current_bucket 
    end 

  end 
end