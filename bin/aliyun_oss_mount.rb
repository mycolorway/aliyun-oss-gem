#!/usr/bin/env ruby 

$:.unshift File.dirname(__FILE__) + '/../lib'  # 增加搜索路径
require 'aliyun-oss'

puts "mount aliyun oss"
oss = AliyunOss::Api.new("","","",{})
puts oss 