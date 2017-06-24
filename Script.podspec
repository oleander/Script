Pod::Spec.new do |s|
  s.name             = 'Script'
  s.version          = '3.0.0'
  s.summary          = 'Run bash script from Swift'
  s.description      = 'Run bash script from within Swift'
  s.homepage         = 'https://github.com/oleander/Script'
  s.license          = { type: 'MIT' }
  s.author           = { 'oleander' => 'linus@oleander.nu' }
  s.source           = { git: 'https://github.com/oleander/Script.git', tag: s.version.to_s }
  s.platform         = :osx, '10.10'
  s.source_files     = 'Sources'
end
