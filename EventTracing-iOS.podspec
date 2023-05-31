Pod::Spec.new do |s|
  s.name             = 'EventTracing-iOS'
  s.version          = (require 'Martin'; Martin::smart_version)  
  s.summary          = 'EventTracing-iOS'

  s.description      = <<-DESC
    EventTracing-iOS
                       DESC

  s.homepage         = 'https://github.com/EventTracing/EventTracing-iOS'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'eventtracing' => 'eventtracing@service.netease.com' }
  s.source           = { :git => 'https://github.com/EventTracing/EventTracing-iOS.git', :tag => s.version.to_s }

  #======= 补充的组件信息, 字段释义见文档: https://docs.popo.netease.com/lingxi/7134ae564a764260b1e2425bb41d2cf6 ========= 
  s.attributes_hash['ne_owners'] = ["xiongxunquan@corp.netease.com", "dingli@corp.netease.com"] 
  s.attributes_hash['ne_biz_tags'] = ["公技", "曙光"] 
  s.attributes_hash['ne_level'] = '0' 
  #============================  

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
