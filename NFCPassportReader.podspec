#
#  Be sure to run `pod spec lint NFCPassportReader.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

    # 1
    s.platform = :ios
    s.ios.deployment_target = '11.0'
    s.name = "NFCPassportReader"
    s.summary = "NFCPassportReader lets a user scan his passport with nfc."
    s.requires_arc = true

    # 2
    s.version = "0.1.9"

    # 3
    s.license = { :type => "MIT", :file => "LICENSE" }

    # 4 - Replace with your name and e-mail address
    s.author = { "Davide Ceresola" => "davide.ceresola@satispay.com" }

    # 5 - Replace this URL with your own GitHub page's URL (from the address bar)
    s.homepage = "https://github.com/dadocere/NFCPassportReader"

    # 6 - Replace this URL with your own Git URL from "Quick Setup"
    s.source = { :git => "https://github.com/dadocere/NFCPassportReader.git",
                 :tag => "#{s.version}" }

    # 7
    s.framework = "UIKit"
    s.weak_framework = "CoreNFC"
    s.dependency 'IDZSwiftCommonCrypto', '~> 0.13.0'

    # 8
    s.source_files = "NFCPassportReader/**/*.{swift}"

    # 9
    s.resources = "NFCPassportReader/**/*.{png,jpeg,jpg,storyboard,xib,xcassets}"

    # 10
    s.swift_version = "5"

end
