Pod::Spec.new do |s|
  s.name         = "RYCommunication"
  s.version      = "1.0.10"
  s.summary      = "附件设备通信库"
  s.description  = <<-DESC
  "一个支持常用通信方式的通信的库，支持iOS ble、mfi、和socket，OSX 蓝牙和USB"
                   DESC
  s.homepage = 'https://github.com/NightDrivers'
  s.license      = "MIT"
  s.author       = { "NightDriver" => "lin_de_chun@sina.com" }
  s.source       = { :git => "https://github.com/NightDrivers/RYCommunication.git", :tag => "#{s.version}" }
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'
  s.default_subspec = "base"
  
  s.subspec 'base' do |ss|
    ss.source_files  = "RYCommunication/base/*.{h,m,c}"
  end
  
  s.subspec 'stream' do |ss|
    ss.ios.source_files  = "RYCommunication/stream/*.{h,m}"
    ss.osx.source_files  = ""
    ss.ios.dependency 'RYCommunication/base'
  end
  
  s.subspec 'mfi' do |ss|
    ss.ios.source_files  = "RYCommunication/mfi/*.{h,m}"
    ss.osx.source_files  = ""
    ss.ios.dependency 'RYCommunication/stream'
  end
  
  s.subspec 'socket' do |ss|
    ss.ios.source_files  = "RYCommunication/socket/*.{h,m}"
    ss.osx.source_files  = ""
    ss.ios.dependency 'RYCommunication/stream'
  end
  
  s.subspec 'ble' do |ss|
    ss.ios.source_files  = "RYCommunication/ble/*.{h,m}"
    ss.osx.source_files  = ""
    ss.ios.dependency 'RYCommunication/base'
  end
  
  s.subspec 'bluetooth' do |ss|
    ss.osx.source_files  = "RYCommunication/bluetooth/*.{h,m}"
    ss.ios.source_files  = ""
    ss.osx.dependency 'RYCommunication/base'
  end
  
  s.subspec 'usb' do |ss|
    ss.osx.source_files  = "RYCommunication/usb/*.{h,m}"
    ss.ios.source_files  = ""
    ss.osx.dependency 'RYCommunication/base'
  end
  
  s.subspec 'lan' do |ss|
    ss.osx.source_files  = ""
    ss.ios.source_files  = "RYCommunication/lan/*.{h,m}"
    ss.ios.dependency 'CocoaAsyncSocket'
  end
end
