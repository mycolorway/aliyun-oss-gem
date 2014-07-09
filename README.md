
访问阿里云开放存储服务oss， ruby SDK， 只实现了部分接口， 比较初级，供参考和学习

#gem 打包命令 

 gem build aliyun-oss.gemspec

#gem 包安装 

 gem install aliyun-oss-0.1.0.gem




#命令行使用方法 ： 

aliyun_oss_rb -H oss.aliyuncs.com -i **** -k  *****

》 这个是命令行提示符

输入help ， 目前实现 如下几个功能， 

》help

ls             -- list location directory contents

cd [LOCATION]  -- change location work dir

pwd

osslist        -- list oss buckets

osscd BUCKET   -- change oss bucket

ossls OBJECT   -- get head info of current bucket object

osspwd         -- show current oss bucket

ossget OBJECT  -- get oss object to location directory

ossurl OBJECT  -- get oss object web url

help

exit


ls  cd  pwd 这3个命令是针对本地工作目录的， 可以对本地的工作目录做更改；

osslist  列出所有 buckets 

osscd    切换当前的 bucket

osspwd   显示当前正在使用的 bucket 

ossls   显示对应的对象资源的头信息 

ossget  下载资源到本地工作目录

ossurl  输出对应资源的外链请求地址 





#开发使用接口
请参考 api.rb 


