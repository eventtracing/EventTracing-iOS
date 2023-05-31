Pod::Spec.new do |s|
  s.name             = 'EventTracing-iOS'
  s.version          = '1.1.3'
  s.summary          = 'EventTracing-iOS'

  s.description      = <<-DESC
    EventTracing-iOS
                       DESC

  s.homepage         = 'https://g.hz.netease.com/cloudmusic-ios-pubtech/EventTracing-iOS'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'eventtracing' => 'eventtracing@service.netease.com' }
  s.source           = { :git => 'ssh://git@g.hz.netease.com:22222/cloudmusic-ios-pubtech/EventTracing-iOS.git', :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'
  s.module_name = 'EventTracing'  
  s.library = 'c++'
  s.pod_target_xcconfig = { 
    'GCC_PRECOMPILE_PREFIX_HEADER' => true
   }

  s.source_files = [
    'EventTracing-iOS/Classes/**/*.{h,m,mm}'
  ]

  s.private_header_files = [
    'EventTracing-iOS/Classes/AOP/**/*.h',
    'EventTracing-iOS/Classes/Categorys/*.h',
    'EventTracing-iOS/Classes/Core/*.h',
    'EventTracing-iOS/Classes/Log/*.h',
    'EventTracing-iOS/Classes/Output/Private/*.h',
    'EventTracing-iOS/Classes/ParamGuard/Private/*.h',
    'EventTracing-iOS/Classes/Refer/Private/*.h',
    'EventTracing-iOS/Classes/Throttle/*.h',
    'EventTracing-iOS/Classes/Traverser/*.h',
    'EventTracing-iOS/Classes/Utils/Private/*.h',
    'EventTracing-iOS/Classes/VTree/Private/*.h',
    'EventTracing-iOS/Classes/VTree/Sync/*.h',
    'EventTracing-iOS/Classes/VTree/Visible/*.h'
  ]
  s.public_header_files = [
    'EventTracing-iOS/Classes/Public/**/*.h',
    'EventTracing-iOS/Classes/VTree/*.h',
    'EventTracing-iOS/Classes/Refer/*.h',
    'EventTracing-iOS/Classes/Output/*.h',
    'EventTracing-iOS/Classes/Diff/*.h',
    'EventTracing-iOS/Classes/ParamGuard/NEEventTracingParamGuardConfiguration.h',
    'EventTracing-iOS/Classes/Exceptions/NEEventTracingExceptionDelegate.h',
    'EventTracing-iOS/Classes/Utils/NSArray+ETEnumerator.h'
  ]

  s.dependency 'JRSwizzle', '~> 1.1.0'
  s.dependency 'BlocksKit', '~> 2.2.5'
end
