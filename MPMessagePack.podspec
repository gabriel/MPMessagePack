Pod::Spec.new do |s|

  s.name         = "MPMessagePack"
  s.version      = "0.1.9"
  s.summary      = "Objective-C library for MessagePack"
  s.homepage     = "https://github.com/gabriel/MPMessagePack"
  s.license      = { :type => "MIT" }
  s.author       = { "Gabriel Handford" => "gabrielh@gmail.com" }
  s.source       = { :git => "https://github.com/gabriel/MPMessagePack.git", :tag => s.version.to_s }
  s.source_files = 'MPMessagePack/**/*.{c,h,m}'
  s.requires_arc = true

end
