Pod::Spec.new do |s|
    s.name         = "React-NoPass"
    s.version      = "1.0.1"
    s.license      = { type: 'Custom license', file: 'LICENSE' }
    s.summary      = "Make it easy to use NoPass react product on your iOS app."
    s.description  = "NoPass SDK is a software developer kit that allows you to build the NoPass 3-factor authentication into your existing mobile applications."
    s.homepage     = "https://www.identite.us/nopass-sdk"

    s.author = { "Identite inc." => "support@identite.us" }
    s.source       = { :git => "https://github.com/identite/nopass.sdk.react.git", :tag => "#{s.version}" }


    s.vendored_frameworks = "asnpbridge.xcframework"
    s.platform = :ios
    # s.swift_version = "5"
    s.ios.deployment_target  = '11.0'
end
