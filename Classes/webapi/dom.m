// -*-  Mode:ObjC; c-basic-offset:4; tab-width:8; indent-tabs-mode:nil -*-

#import "dom.h"

@implementation XmlNode
@synthesize name, parent, attributes, children, text;

- (id)init
{
    self = [super init];
    name = nil;
    parent = nil;
    attributes = nil;
    children = [[NSMutableArray alloc] init];
    return self;
}

- (void)dealloc
{
    [name release];
    [attributes release];
    [children release];
    [super dealloc];
}

- (XmlNode*)findNode:(NSString *)a_name
{
    for (XmlNode *n in children) {
        if ([n.name isEqualToString:a_name]) {
            return n;
        }
        XmlNode *found = [n findNode:a_name];
        if (found) {
            return found;
        }
    }
    return nil;
}

- (XmlNode*)findSibling
{
    if (parent == nil) return nil;

    bool foundme = NO;
    for (XmlNode *n in parent.children) {
        if (n == self) {
            foundme = YES;
        }
        else if (foundme && [n.name isEqualToString:name]) {
            return n;
        }
    }
    return nil;
}

// debug
- (void)dump
{
    [self dumpsub:0];
}

- (void)dumpsub:(int)depth
{
    NSLog(@"%d:%@", depth, name);
    for (XmlNode *n in children) {
        [n dumpsub:depth + 1];
    }
}

@end

@implementation DomParser

- (id)init
{
    self = [super init];
    curString = [[NSMutableString alloc] initWithCapacity:100];
    return self;
}

- (void)dealloc
{
    [curString release];
    [super dealloc];
}

- (XmlNode *)parse:(NSData *)data
{
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    [parser setDelegate:self];
    [parser setShouldResolveExternalEntities:YES];

    XmlNode *rootNode = [[[XmlNode alloc] init] autorelease];
    curNode = rootNode;

    BOOL result = [parser parse];
    [parser release];

    if (!result) {
        return nil;
    }
        
    return curNode;
}

// 開始タグの処理
- (void)parser:(NSXMLParser*)parser didStartElement:(NSString*)elem namespaceURI:(NSString *)nspace qualifiedName:(NSString *)qname attributes:(NSDictionary *)attributes
{
    [curString setString:@""];

    XmlNode *node = [[XmlNode alloc] init];
    node.name = elem;
    node.attributes = [attributes copy];

    node.parent = curNode;
    [curNode.children addObject:node];
    curNode = node;
    [node release];
}

// 文字列処理
- (void)parser:(NSXMLParser*)parser foundCharacters:(NSString*)string
{
    [curString appendString:string];
}

// 終了タグの処理
- (void)parser:(NSXMLParser*)parser didEndElement:(NSString*)elem namespaceURI:(NSString *)nspace qualifiedName:(NSString *)qname
{
    curNode.text = [NSString stringWithString:curString];
    curNode = curNode.parent;
}

@end
