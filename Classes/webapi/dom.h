// -*-  Mode:ObjC; c-basic-offset:4; tab-width:8; indent-tabs-mode:nil -*-

// simple / adhoc DOM

#import <UIKit/UIKit.h>

@interface XmlNode : NSObject {
    NSString *name;
    XmlNode *parent;
    NSString *text;
    NSMutableDictionary *attributes;
    NSMutableArray *children;
}

@property(nonatomic, retain) NSString *name;
@property(nonatomic, assign) XmlNode *parent;
@property(nonatomic, retain) NSString *text;
@property(nonatomic, retain) NSDictionary *attributes;
@property(nonatomic, retain) NSMutableArray *children;

@end

@interface DomParser : NSObject <NSXMLParserDelegate> {
    NSMutableString *curString;
    XmlNode *curNode;
}

- (XmlNode*)parse:(NSData *data);

@end
