#import "AMQValues.h"

typedef NS_ENUM(char, AMQFrameType) {
    AMQFrameTypeMethod = 1,
    AMQFrameTypeContentHeader,
    AMQFrameTypeContentBody,
    AMQFrameTypeHeartbeat = 8
};

@interface AMQFrame : MTLModel<AMQEncoding,AMQParseable>
@property (nonnull, nonatomic, copy, readonly) NSNumber *channelNumber;
@property (nonnull, nonatomic, readonly) id<AMQPayload> payload;
- (nonnull instancetype)initWithChannelNumber:(nonnull NSNumber *)channelNumber
                                      payload:(nonnull id<AMQEncoding>)payload;
- (BOOL)isHeartbeat;
@end
