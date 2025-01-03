#import <Foundation/Foundation.h>

#define LOG_TAG @"APP"
#define setLoggable(lv) [[Logger sharedInstance] setLoggableWithLevel:lv]
#define DLog(fmt, ...)  [[Logger sharedInstance] logMessage:[NSString stringWithFormat:fmt, ##__VA_ARGS__] withLogLevel:LogLevelDebug tag:LOG_TAG]
#define DLogMethod(fmt, ...)  [[Logger sharedInstance] logMessage:[NSString stringWithFormat:@"%s: %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:fmt, ##__VA_ARGS__]] withLogLevel:LogLevelDebug tag:LOG_TAG]
#define DLogMethodLine(fmt, ...)  [[Logger sharedInstance] logMessage:[NSString stringWithFormat:@"%s#%d: %@", __PRETTY_FUNCTION__, __LINE__, [NSString stringWithFormat:fmt, ##__VA_ARGS__]] withLogLevel:LogLevelDebug tag:LOG_TAG]
#define ILog(fmt, ...)  [[Logger sharedInstance] logMessage:[NSString stringWithFormat:fmt, ##__VA_ARGS__] withLogLevel:LogLevelInfo tag:LOG_TAG]
#define ILogMethod(fmt, ...)  [[Logger sharedInstance] logMessage:[NSString stringWithFormat:@"%s: %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:fmt, ##__VA_ARGS__]] withLogLevel:LogLevelInfo tag:LOG_TAG]
#define ILogMethodLine(fmt, ...)  [[Logger sharedInstance] logMessage:[NSString stringWithFormat:@"%s#%d: %@", __PRETTY_FUNCTION__, __LINE__, [NSString stringWithFormat:fmt, ##__VA_ARGS__]] withLogLevel:LogLevelInfo tag:LOG_TAG]
#define WLog(fmt, ...)  [[Logger sharedInstance] logMessage:[NSString stringWithFormat:fmt, ##__VA_ARGS__] withLogLevel:LogLevelWarning tag:LOG_TAG]
#define WLogMethod(fmt, ...)  [[Logger sharedInstance] logMessage:[NSString stringWithFormat:@"%s: %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:fmt, ##__VA_ARGS__]] withLogLevel:LogLevelWarning tag:LOG_TAG]
#define WLogMethodLine(fmt, ...)  [[Logger sharedInstance] logMessage:[NSString stringWithFormat:@"%s#%d: %@", __PRETTY_FUNCTION__, __LINE__, [NSString stringWithFormat:fmt, ##__VA_ARGS__]] withLogLevel:LogLevelWarning tag:LOG_TAG]
#define WLogCallStack()  [[Logger sharedInstance] logMessage:[NSString stringWithFormat:@"%@", NSThread.callStackSymbols] withLogLevel:LogLevelWarning tag:LOG_TAG]
#define ELog(fmt, ...)  [[Logger sharedInstance] logMessage:[NSString stringWithFormat:fmt, ##__VA_ARGS__] withLogLevel:LogLevelError tag:LOG_TAG]
#define ELogMethod(fmt, ...)  [[Logger sharedInstance] logMessage:[NSString stringWithFormat:@"%@: %@", NSStringFromSelector(_cmd), [NSString stringWithFormat:fmt, ##__VA_ARGS__]] withLogLevel:LogLevelError tag:LOG_TAG]
#define ELogMethodLine(fmt, ...)  [[Logger sharedInstance] logMessage:[NSString stringWithFormat:@"%@#%d: %@", NSStringFromSelector(_cmd), __LINE__, [NSString stringWithFormat:fmt, ##__VA_ARGS__]] withLogLevel:LogLevelError tag:LOG_TAG]
#define DLogMethodStart() DLogMethod(@"Start")
#define DLogMethodStartWithParameter(fmt, ...)  [[Logger sharedInstance] logMessage:[NSString stringWithFormat:@"Start Input(%@)", [NSString stringWithFormat:fmt, ##__VA_ARGS__]] withLogLevel:LogLevelDebug tag:LOG_TAG]
#define DLogMethodEnd() DLogMethod(@"End")
#define DLogMethodEnds(num) DLogMethod(@"End(%d)", num)
#define DLogMethodEndWithReturn(fmt, ...)  [[Logger sharedInstance] logMessage:[NSString stringWithFormat:@"End Return(%@)", [NSString stringWithFormat:fmt, ##__VA_ARGS__]] withLogLevel:LogLevelDebug tag:LOG_TAG]

typedef NS_ENUM(NSInteger, LogLevel) {
    LogLevelVerbose = 0x02,
    LogLevelDebug,
    LogLevelInfo,
    LogLevelWarning,
    LogLevelError,
    LogLevelNone
};

@interface Logger : NSObject

@property (nonatomic, assign) LogLevel logLevel;

+ (instancetype)sharedInstance;
- (void)logMessage:(NSString *)message withLogLevel:(LogLevel)logLevel tag:(NSString *)tag;
- (void)setLoggableWithLevel:(LogLevel)level;
@end
