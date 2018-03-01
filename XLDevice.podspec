Pod::Spec.new do |s|

s.name         = "XLDevice"
s.version      = "1.0.0"
s.summary      = "这是一个设备信息管理工具"

s.description  = <<-DESC
                        LZTool 是一个用于保存一些常用工具类的工具
                 DESC

s.homepage     = "https://github.com/muxueChen/PodTest"

s.license      = "MIT"

s.author    = "暮雪"
s.platform     = :ios, "8.0"

s.source       = { :git => "https://github.com/muxueChen/PodTest.git", :tag => "1.0.0" }
s.source_files = "XLDeviceManager/XLDevice.{h,m}"

s.requires_arc = true

end
