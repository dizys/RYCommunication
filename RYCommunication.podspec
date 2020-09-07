Pod::Spec.new do |s|
  s.name         = "RYCommunication"
  s.version      = "1.0.0"
  s.summary      = "附件设备通信库"
  s.description  = <<-DESC
  "一个支持常用通信方式的通信的库，同时支持ble、mfi、和socket"
                   DESC
  s.homepage = 'https://github.com/NightDrivers'
  s.license      = "MIT"
  s.author       = { "NightDriver" => "lin_de_chun@sina.com" }
  s.source       = { :git => "https://github.com/NightDrivers/RYCommunication.git", :tag => "#{s.version}" }
  s.ios.deployment_target = '8.0'
  
  s.subspec 'base' do |ss|
    ss.source_files  = "RYCommunication/base/*.{h,m}"
  end
  
  s.subspec 'stream' do |ss|
    ss.source_files  = "RYCommunication/stream/*.{h,m}"
    ss.dependency 'RYCommunication/base'
  end
  
  s.subspec 'mfi' do |ss|
    ss.source_files  = "RYCommunication/mfi/*.{h,m}"
    ss.dependency 'RYCommunication/stream'
  end
  
  s.subspec 'socket' do |ss|
    ss.source_files  = "RYCommunication/socket/*.{h,m}"
    ss.dependency 'RYCommunication/stream'
  end
  
  s.subspec 'ble' do |ss|
    ss.source_files  = "RYCommunication/ble/*.{h,m}"
    ss.dependency 'RYCommunication/base'
  end
end
