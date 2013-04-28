Pod::Spec.new do |spec|
  spec.name          = 'CTDataStoreManager'
  spec.version       = '1.0.0'
  spec.platform      = :ios, '5.0'
  spec.license       = 'MIT'
  spec.source        = { :git => 'https://github.com/ebf/CTDataStoreManager.git', :tag => spec.version.to_s }
  spec.source_files  = 'CTDataStoreManager/CTDataStoreManager/*.{h,m}', 'CTDataStoreManager/CTDataStoreManager/Framework Additions/**/**/*.{h,m}'
  spec.exclude_files = 'CTDataStoreManager/CTDataStoreManager/Framework Additions/Foundation/NSManagedObjectContext/*.{h,m}'
  spec.frameworks    = 'Foundation', 'UIKit', 'CoreData'
  spec.requires_arc  = true
  spec.homepage      = 'https://github.com/ebf/CTDataStoreManager'
  spec.summary       = 'Simple CoreData stack with 2 NSManagedObjectContexts.'
  spec.author        = { 'Oliver Letterer' => 'oliver.letterer@gmail.com' }

  spec.subspec 'no-arc' do |sp|
    sp.source_files = 'CTDataStoreManager/CTDataStoreManager/Framework Additions/Foundation/NSManagedObjectContext/*.{h,m}'
    sp.requires_arc = false
  end

  spec.prefix_header_contents = <<-EOS
#ifdef __OBJC__
    #import <Foundation/Foundation.h>
    #import <CoreData/CoreData.h>
    #import <objc/runtime.h>
#endif

#ifndef __weakSelf
#define __weakSelf __weak typeof(self) weakSelf = self
#endif

#ifndef __strongSelf
#define __strongSelf __strong typeof(weakSelf) strongSelf = weakSelf
#endif

#ifndef _DLog

# define _DLog(format, ...) NSLog((@"%s [%d] " format), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)

#endif
 
#ifndef DLog

# ifdef DEBUG
#  define DLog(format, ...) _DLog(format, ##__VA_ARGS__)
# else  
#   define DLog(...)  
# endif

#endif
EOS
end