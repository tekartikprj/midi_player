#import "MidiPlayerPlugin.h"
#import <AVFoundation/AVFoundation.h>

static bool _log = false;
static NSString *const _channelName = @"tekartik_midi_player";
static NSString *const _methodGetPlatformVersion = @"getPlatformVersion";
static NSString *const _methodDebugMode = @"debugMode";
static NSString *const _methodResume = @"resume";
static NSString *const _methodPause = @"pause";
static NSString *const _methodClose = @"close";
static NSString *const _methodLoadFile = @"loadFile";
static NSString *const _methodCurrentPosition = @"currentPosition";
static NSString *const _methodPlaying = @"playing";
static NSString *const _methodDuration = @"duration";
static NSString *const _methodSeek = @"seek";

// from native
static NSString *const _methodOnComplete = @"onComplete";

static NSString *const _paramId = @"id";
static NSString *const _paramPath = @"path";
static NSString *const _paramMillis = @"millis";
static NSString *const _paramPlaying = @"playing";

@implementation Query

@synthesize methodCall, result;

+ (Query*)queryWithMethodCall:(FlutterMethodCall *)methodCall result:(FlutterResult)result {
    Query* query = [Query new];
    query.methodCall = methodCall;
    query.result = result;
    return query;
}

- (NSString*)method {
    return self.methodCall.method;
}

- (id)arguments {
    return self.methodCall.arguments;
}

@end

@implementation MidiPlayerPlugin



@synthesize _channel, _players;

- (id)init {
    self = [super init];
    if (self) {
        _players = [[NSMutableDictionary alloc] init];
    }
    return self;
}
- (void)handleGetPlatformVersion:(Query*)query {
    query.result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
}
- (void)handleDebugMode:(Query*)query {
    NSNumber* on = (NSNumber*)query.arguments;
    _log = [on boolValue];
    NSLog(@"Debug mode %d", _log);
    //_extra_log = __extra_log && _log;
    query.result(nil);
}

- (Player*)getPlayerOrError:(Query*)query {
    NSNumber* playerId = query.arguments[_paramId];
    Player* player;
    if (playerId != nil) {
        player = _players[playerId];
    }
    if (player == nil) {
        query.result([FlutterError errorWithCode:@"tekartik_midi_player"
                                         message: @"get player failed"
                                         details:nil]);
    }
    return player;
}
- (void)handleLoadFile:(Query*)query {
    NSNumber* playerId = query.arguments[_paramId];
    NSString* path = query.arguments[_paramPath];
    
    if (_log) {
        NSLog(@"Loading file player %@ %@", playerId, path);
    }

    // Set the instruments
    NSURL * bankURL;
    
    NSString *bankPath = [[NSBundle mainBundle] pathForResource:@"sounds" ofType:@"sf2"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:bankPath])
    {
        bankURL = [NSURL fileURLWithPath:bankPath isDirectory:NO];
    } else {
        query.result([FlutterError errorWithCode:@"tekartik_midi_player"
                                         message: @"Loading sounds failed"
                                         details:nil]);
    }
    if (_log) {
        NSLog(@"Loaded bank %@", bankURL);
    }
    NSError* error;
    NSURL* fileURL = [NSURL fileURLWithPath:path isDirectory:NO];
    if (_log) {
        NSLog(@"Loaded file %@", fileURL);
    }
    AVMIDIPlayer* avMidiPlayer = [[AVMIDIPlayer alloc] initWithContentsOfURL:fileURL soundBankURL: bankURL error: &error];
    if(avMidiPlayer != nil) {
        Player* player = [Player new];
        player.avMidiPlayer = avMidiPlayer;
        player.playerId = playerId;
        _players[playerId] =  player;
        [avMidiPlayer prepareToPlay];
    
        if (_log) {
            NSLog(@"prepared file %@", playerId);
        }
    }
    query.result(nil);
}

- (void)handleResume:(Query*)query {
    Player* player = [self getPlayerOrError:query];
    if (player != nil) {
        if (_log) {
            NSLog(@"playing file %@", player.playerId);
        }
        [player.avMidiPlayer play:^{
            if (_log) {
                NSLog(@"onComplete file %@", player.playerId);
            }
            [self._channel invokeMethod:_methodOnComplete arguments:@{_paramId: player.playerId}];
        }];
        query.result(nil);
    }
}

- (void)handlePause:(Query*)query {
    Player* player = [self getPlayerOrError:query];
    if (player != nil) {
        [player.avMidiPlayer stop];
        query.result(nil);
    }
}

- (void)handleClose:(Query*)query {
    Player* player = [self getPlayerOrError:query];
    if (player != nil) {
        [player.avMidiPlayer stop];
        [_players removeObjectForKey:player.playerId];
        query.result(nil);
    }
}

- (void)handleSeek:(Query*)query {
    Player* player = [self getPlayerOrError:query];
    if (player != nil) {
        NSNumber* millis = query.arguments[_paramMillis];
        player.avMidiPlayer.currentPosition =  timeIntervalFromMillis(millis);
        query.result(nil);
    }
}

- (void)handleCurrentPosition:(Query*)query {
    Player* player = [self getPlayerOrError:query];
    if (player != nil) {
        NSNumber* millis = [NSNumber numberWithLong:[[NSNumber numberWithDouble:player.avMidiPlayer.currentPosition * 1000] longValue]];
        query.result(@{_paramMillis: millis});
    }
}

- (void)handleDuration:(Query*)query {
    Player* player = [self getPlayerOrError:query];
    if (player != nil) {
        NSNumber* millis = [NSNumber numberWithLong:[[NSNumber numberWithDouble:player.avMidiPlayer.duration * 1000] longValue]];
        query.result(@{_paramMillis: millis});
    }
}

- (void)handlePlaying:(Query*)query {
    Player* player = [self getPlayerOrError:query];
    if (player != nil) {
        NSNumber* playing = [NSNumber numberWithBool:player.avMidiPlayer.isPlaying];
        query.result(@{_paramPlaying: playing});
    }
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:_channelName
                                     binaryMessenger:[registrar messenger]];
    MidiPlayerPlugin* instance = [[MidiPlayerPlugin alloc] init];
    instance._channel = channel;
    [registrar addMethodCallDelegate:instance channel:channel];
    
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    Query* query = [Query queryWithMethodCall:call result:result];
    NSString* method = query.method;
    if ([_methodGetPlatformVersion isEqualToString:method]) {
        [self handleGetPlatformVersion: query];
    } else if ([_methodDebugMode isEqualToString:method]) {
        [self handleDebugMode: query];
    } else if ([_methodLoadFile isEqualToString:method]) {
        [self handleLoadFile: query];
    } else if ([_methodResume isEqualToString:method]) {
        [self handleResume: query];
    } else if ([_methodPause isEqualToString:method]) {
        [self handlePause: query];
    } else if ([_methodClose isEqualToString:method]) {
        [self handleClose: query];
    } else if ([_methodDuration isEqualToString:method]) {
        [self handleDuration: query];
    } else if ([_methodCurrentPosition isEqualToString:method]) {
        [self handleCurrentPosition: query];
    } else if ([_methodPlaying isEqualToString:method]) {
        [self handlePlaying: query];
    } else if ([_methodSeek isEqualToString:method]) {
        [self handleSeek: query];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

NSTimeInterval timeIntervalFromMillis(NSNumber *millis) {
    NSTimeInterval timeInterval = [millis doubleValue] / 1000.0;
    if (timeInterval < 0) {
        return 0;
    }
    return timeInterval;
}

@end

@implementation Player

@synthesize avMidiPlayer, playerId;

@end

