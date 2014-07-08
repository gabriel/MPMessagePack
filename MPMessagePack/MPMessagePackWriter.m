//
//  MPMessagePackWriter.m
//  MPMessagePack
//
//  Created by Gabriel on 7/3/14.
//  Copyright (c) 2014 Gabriel Handford. All rights reserved.
//

#import "MPMessagePackWriter.h"

#include "cmp.h"

#import "MPOrderedDictionary.h"

@interface MPMessagePackWriter ()
@property NSMutableData *data;
@end

@implementation MPMessagePackWriter

- (size_t)write:(const void *)data count:(size_t)count {
  [_data appendBytes:data length:count];
  return count;
}

static bool mp_reader(cmp_ctx_t *ctx, void *data, size_t limit) {
  return 0;
}

static size_t mp_writer(cmp_ctx_t *ctx, const void *data, size_t count) {
  MPMessagePackWriter *mp = (__bridge MPMessagePackWriter *)ctx->buf;
  return [mp write:data count:count];
}

- (NSData *)writeObject:(id)obj error:(NSError * __autoreleasing *)error {
  _data = [NSMutableData data];
  
  cmp_ctx_t ctx;
  cmp_init(&ctx, (__bridge void *)self, mp_reader, mp_writer);
  
  if (![self writeObject:obj context:&ctx error:error]) {
    return nil;
  }
  
  return _data;
}

+ (NSData *)writeObject:(id)obj error:(NSError * __autoreleasing *)error {
  MPMessagePackWriter *messagePack = [[MPMessagePackWriter alloc] init];
  [messagePack writeObject:obj error:error];
  return messagePack.data;
}

- (BOOL)writeNumber:(NSNumber *)number context:(cmp_ctx_t *)context error:(NSError * __autoreleasing *)error {
  if (strcmp([number objCType], @encode(BOOL)) == 0) {
    cmp_write_bool(context, number.boolValue);
    return YES;
  }
  
  CFNumberType numberType = CFNumberGetType((CFNumberRef)number);
  switch (numberType)	{
    case kCFNumberSInt8Type:
    case kCFNumberCharType:
      cmp_write_s8(context, number.charValue);
      break;
    case kCFNumberSInt16Type:
    case kCFNumberShortType:
      cmp_write_s16(context, number.shortValue);
      break;
    case kCFNumberSInt32Type:
    case kCFNumberIntType:
    case kCFNumberLongType:
    case kCFNumberCFIndexType:
    case kCFNumberNSIntegerType:
      cmp_write_s32(context, number.intValue);
      break;
    case kCFNumberSInt64Type:
    case kCFNumberLongLongType:
      cmp_write_s64(context, number.longLongValue);
      break;
    case kCFNumberFloat32Type:
    case kCFNumberFloatType:
    case kCFNumberCGFloatType:
      cmp_write_float(context, number.floatValue);
      break;
    case kCFNumberFloat64Type:
    case kCFNumberDoubleType:
      cmp_write_double(context, number.doubleValue);
      break;
    default:
      if (error) *error = [NSError errorWithDomain:@"MPMessagePack" code:101 userInfo:@{NSLocalizedDescriptionKey: @"Unable to write number"}];
      return NO;
  }
  
  return YES;
}

- (BOOL)writeObject:(id)obj context:(cmp_ctx_t *)context error:(NSError * __autoreleasing *)error {
  if ([obj isKindOfClass:[NSArray class]]) {
    cmp_write_array(context, (uint32_t)[obj count]);
    for (id element in obj) {
      if (![self writeObject:element context:context error:error]) {
        return NO;
      }
    }
  } else if ([obj isKindOfClass:[NSDictionary class]] || [obj isKindOfClass:[MPOrderedDictionary class]]) {
    cmp_write_map(context, (uint32_t)[obj count]);
    for (id key in obj) {
      if (![self writeObject:key context:context error:error]) {
        return NO;
      }
      if (![self writeObject:[obj objectForKey:key] context:context error:error]) {
        return NO;
      }
    }
  } else if ([obj isKindOfClass:[NSString class]]) {
    const char *str = ((NSString*)obj).UTF8String;
    size_t len = strlen(str);
    cmp_write_str(context, str, (uint32_t)len);
  } else if ([obj isKindOfClass:[NSNumber class]]) {
    [self writeNumber:obj context:context error:error];
  } else if ([obj isKindOfClass:[NSNull class]]) {
    cmp_write_nil(context);
  } else if ([obj isKindOfClass:[NSData class]]) {
    cmp_write_bin(context, [obj bytes], (uint32_t)[obj length]);
  } else {
    NSString *errorDescription = [NSString stringWithFormat:@"Unable to write object: %@", obj];
    if (error) *error = [NSError errorWithDomain:@"MPMessagePack" code:102 userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
    return NO;
  }
  return YES;
}

@end
