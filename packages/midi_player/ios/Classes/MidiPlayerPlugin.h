#import <Flutter/Flutter.h>
#import <AVFoundation/AVFoundation.h>
@interface Query : NSObject

@property (atomic, retain) FlutterMethodCall* methodCall;
@property (atomic, assign) FlutterResult result;

+ (Query*)queryWithMethodCall:(FlutterMethodCall *)methodCall result:(FlutterResult)result;
- (NSString*)method;
- (id)arguments;

@end

@interface MidiPlayerPlugin : NSObject<FlutterPlugin>

@property (atomic, retain) FlutterMethodChannel *_channel;
@property (atomic, retain) NSMutableDictionary* _players;

@end

@interface Player : NSObject

@property (atomic, retain) AVMIDIPlayer* avMidiPlayer;
@property (atomic, retain) NSNumber* playerId;

@end
