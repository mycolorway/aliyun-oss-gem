# coding: utf-8 

require File.dirname(__FILE__) + '/lib/aliyun-oss/version'
require 'date'

Gem::Specification.new do |s|  
  s.name        = 'aliyun-oss'  
  s.version     = AliyunOss::VERSION   
  s.date        = Date.today.to_s 
  s.summary     = "aliyun-oss"  
  s.description = "aliyun oss gem"  
  s.authors     = ["WangDong"]  
  s.email       = 'wangdong@mycolorway.com'  
  s.license     = "GPL version 2"
  #s.platform    = Gem::Platform::RUBY
  s.homepage    = "http://github.com/mycolorway/aliyun-oss-gem" 

  s.files             = `git ls-files`.split("\n")
  s.test_files        = `git ls-files -z spec/`.split("\n")
  s.executables       = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths     = %w(lib)
  s.required_ruby_version = '>= 1.9.2'

  s.add_development_dependency('rspec', '~> 2.4') 
  s.add_dependency("rest-client", "~> 1.6") 
  s.add_dependency("multi_xml", "~> 0.5") 
end  
