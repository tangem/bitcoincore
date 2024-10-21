Pod::Spec.new do |s|
  s.name             = 'BitcoinCore.swift'
  s.module_name      = 'BitcoinCore'
  s.version          = '0.0.21'
  s.summary          = 'Core library Bitcoin derived wallets for Swift.'

  s.description      = <<-DESC
BitcoinCore implements Bitcoin core protocol in Swift. It is an implementation of the Bitcoin SPV protocol written (almost) entirely in swift.
                       DESC

  s.homepage         = 'https://github.com/horizontalsystems/bitcoin-kit-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Horizontal Systems' => 'hsdao@protonmail.ch' }
  s.source           = { git: 'https://github.com/horizontalsystems/bitcoin-kit-ios.git', tag: "bitcoin-core-#{s.version}" }
  s.social_media_url = 'http://horizontalsystems.io/'

  s.ios.deployment_target = '15.0'
  s.swift_version = '5'

  s.source_files = 'BitcoinCore/Classes/**/*.swift'

  s.requires_arc = true
end
