// -*-  Mode:ObjC; c-basic-offset:4; tab-width:8; indent-tabs-mode:nil -*-

#import "dom.h"

@implementation XmlNode
@synthesize name, parent, attributes, children;

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

- (XmlNode *)parse:(NSData *data)
{
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    [parser setDelegate:self];
    [parser setShouldResolveExternalEntities:YES];

    XmlNode *rootNode = [[XmlNode alloc] init];
    curNode = rootNode;

    BOOL result = [parser parse];
    [parser release];

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
