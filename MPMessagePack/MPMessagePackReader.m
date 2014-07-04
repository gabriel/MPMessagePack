//
//  MPMessagePackReader.m
//  MPMessagePack
//
//  Created by Gabriel on 7/3/14.
//  Copyright (c) 2014 Gabriel Handford. All rights reserved.
//

#import "MPMessagePackReader.h"

#include "cmp.h"

@interface MPMessagePackReader ()
@property NSData *data;
@property size_t index;
@end

@implementation MPMessagePackReader

- (id)readFromContext:(cmp_ctx_t *)context {
  cmp_object_t obj;
  if (!cmp_read_object(context, &obj)) {
    NSAssert(NO, @"Unable to read");
    return nil;
  }
  
  switch (obj.type) {

    case CMP_TYPE_NIL: return [NSNull null];
    case CMP_TYPE_BOOLEAN: return @(obj.as.boolean);
      
    case CMP_TYPE_BIN8:
    case CMP_TYPE_BIN16:
    case CMP_TYPE_BIN32: {
      uint32_t length = obj.as.bin_size;
      if (length == 0) return [NSData data];
      NSMutableData *data = [NSMutableData dataWithLength:length];
      context->read(context, [data mutableBytes], length);
      return data;
    }

    case CMP_TYPE_POSITIVE_FIXNUM: return @(obj.as.u8);
    case CMP_TYPE_NEGATIVE_FIXNUM:return @(obj.as.s8);
    case CMP_TYPE_FLOAT: return @(obj.as.flt);
    case CMP_TYPE_DOUBLE: return @(obj.as.dbl);
    case CMP_TYPE_UINT8: return @(obj.as.u8);
    case CMP_TYPE_UINT16: return @(obj.as.u16);
    case CMP_TYPE_UINT32: return @(obj.as.u32);
    case CMP_TYPE_UINT64: return @(obj.as.u64);
    case CMP_TYPE_SINT8: return @(obj.as.s8);
    case CMP_TYPE_SINT16: return @(obj.as.s16);
    case CMP_TYPE_SINT32: return @(obj.as.s32);
    case CMP_TYPE_SINT64: return @(obj.as.s64);

    case CMP_TYPE_FIXSTR:
    case CMP_TYPE_STR8:
    case CMP_TYPE_STR16:
    case CMP_TYPE_STR32: {
      uint32_t length = obj.as.str_size;
      if (length == 0) return @"";
      NSMutableData *data = [NSMutableData dataWithLength:length];
      context->read(context, [data mutableBytes], length);
      return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }

    case CMP_TYPE_FIXARRAY:
    case CMP_TYPE_ARRAY16:
    case CMP_TYPE_ARRAY32: {
      uint32_t length = obj.as.array_size;
      return [self readArrayFromContext:context length:length];
    }
      
    case CMP_TYPE_FIXMAP:
    case CMP_TYPE_MAP16:
    case CMP_TYPE_MAP32: {
      uint32_t length = obj.as.map_size;
      return [self readDictionaryFromContext:context length:length];
    }
      
    case CMP_TYPE_EXT8:
    case CMP_TYPE_EXT16:
    case CMP_TYPE_EXT32:
    case CMP_TYPE_FIXEXT1:
    case CMP_TYPE_FIXEXT2:
    case CMP_TYPE_FIXEXT4:
    case CMP_TYPE_FIXEXT8:
    case CMP_TYPE_FIXEXT16:
      NSAssert(NO, @"Unable to read");
      return nil;

    default:
      NSAssert(NO, @"Unable to read");
      return nil;
  }
}

- (NSMutableArray *)readArrayFromContext:(cmp_ctx_t *)context length:(uint32_t)length {
  NSMutableArray *array = [NSMutableArray arrayWithCapacity:length];
  for (NSInteger i = 0; i < length; i++) {
    id obj = [self readFromContext:context];
    NSAssert(obj, @"Unable to read");
    [array addObject:obj];
  }
  return array;
}

- (NSMutableDictionary *)readDictionaryFromContext:(cmp_ctx_t *)context length:(uint32_t)length {
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:length];
  for (NSInteger i = 0; i < length; i++) {
    id key = [self readFromContext:context];
    NSAssert(key, @"Unable to read dict key");
    id value = [self readFromContext:context];
    NSAssert(value, @"Unable to read dict value");
    dict[key] = value;
  }
  return dict;
}

- (size_t)read:(void *)data limit:(size_t)limit {
  if (_index + limit > [_data length]) return 0;
  [_data getBytes:data range:NSMakeRange(_index, limit)];
  
  //NSData *read = [NSData dataWithBytes:data length:limit];
  //NSLog(@"Read bytes: %@", read);
  
  _index += limit;
  return limit;
}

static bool mp_reader(cmp_ctx_t *ctx, void *data, size_t limit) {
  MPMessagePackReader *mp = (__bridge MPMessagePackReader *)ctx->buf;
  return [mp read:data limit:limit];
}

static size_t mp_writer(cmp_ctx_t *ctx, const void *data, size_t count) {
  return 0;
}

- (id)readData:(NSData *)data {
  _data = data;
  _index = 0;
  
  cmp_ctx_t ctx;
  cmp_init(&ctx, (__bridge void *)self, mp_reader, mp_writer);
  return [self readFromContext:&ctx];
}

+ (id)readData:(NSData *)data {
  MPMessagePackReader *messagePackReader = [[MPMessagePackReader alloc] init];
  return [messagePackReader readData:data];
}

@end
