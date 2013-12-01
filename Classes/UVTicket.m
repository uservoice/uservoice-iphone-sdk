//
//  UVTicket.m
//  UserVoice
//
//  Created by Scott Rutherford on 26/04/2011.
//  Copyright 2011 UserVoice Inc. All rights reserved.
//


// format                String - xml, json
// ticket[custom_field_values][_field_name_] String - Replace _field_name_ with the name of your custom field
// ticket[lang]          String
// ticket[message]       String - required
// ticket[referrer]      String
// ticket[subject]       String - required
// ticket[submitted_via] String - Your name for where this ticket came from (ex: web, email)
// ticket[user_agent]    String

#import "UVTicket.h"
#import "UVBaseModel.h"
#import "UVCustomField.h"
#import "UVSession.h"
#import "UVConfig.h"
#import "UVUtils.h"

#ifdef UV_FILE_UPLOADS
//Required for detecting content type
#import <MobileCoreServices/MobileCoreServices.h>

@interface UVTicket()

+ (NSString*) fileMIMEType:(NSString*) file;

@end

#endif


@implementation UVTicket

+ (id)createWithMessage:(NSString *)message
  andEmailIfNotLoggedIn:(NSString *)email
                andName:(NSString *)name
        andCustomFields:(NSDictionary *)fields
            andDelegate:(id)delegate {
    
    NSString *path = [self apiPath:@"/tickets.json"];
    
    // Create the request JSON starting with authentication
    
    NSMutableDictionary *jsonRoot = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     email   == nil ? @"" : email,   @"email",
                                     name    == nil ? @"" : name,    @"display_name",
                                     nil];
    
    NSMutableDictionary *externalIds = [[NSMutableDictionary alloc] init];
    
    for (NSString *scope in [UVSession currentSession].externalIds) {
        NSString *identifier = [[UVSession currentSession].externalIds valueForKey:scope];
        [externalIds setObject:identifier forKey:scope];
    }
    
    if([externalIds count] > 0){
        [jsonRoot setObject:[NSDictionary dictionaryWithObject:externalIds forKey:@"external_ids"] forKey:@"created_by"];
    }
    
    // Create the ticket
    
    NSMutableDictionary *ticket = [NSMutableDictionary dictionaryWithObject:message == nil ? @"" : message
                                                                     forKey: @"message"];
    
    NSDictionary *defaultFields = [UVSession currentSession].config.customFields;
    NSMutableDictionary *customFieldValues = [[NSMutableDictionary alloc] init];
    
    for (NSString *name in [defaultFields keyEnumerator]) {
        [customFieldValues setObject:[defaultFields objectForKey:name] forKey:name];
    }
    
    for (NSString *name in [fields keyEnumerator]) {
        [customFieldValues setObject:[fields objectForKey:name] forKey:name];
    }
    
    [ticket setObject:customFieldValues forKey:@"custom_field_values"];
    
    if ([UVSession currentSession].config.extraTicketInfo != nil) {
        NSString *messageText = [NSString stringWithFormat:@"%@\n\n%@", message, [UVSession currentSession].config.extraTicketInfo];
        [ticket setObject:messageText forKey:@"message"];
    }

#ifdef UV_FILE_UPLOADS

    // Attachments
    
    
    if ([UVSession currentSession].config.attachmentFilePaths != nil) {

        NSMutableArray* attachments = [[NSMutableArray alloc] init];

        //Loop over the attachment files so see which exists
        
        for(NSString *attachmentFilePath in [UVSession currentSession].config.attachmentFilePaths){
            
            if([[NSFileManager defaultManager] fileExistsAtPath:attachmentFilePath]){
                
                NSData *fileData = [[NSData alloc] initWithContentsOfFile:attachmentFilePath];
                                
                NSString *base64Data = [UVUtils encodeData64:fileData];
                
                NSString* mimeType = [self fileMIMEType:attachmentFilePath];
                if(mimeType == nil) mimeType = @"application/octet-stream";

                [attachments addObject:[NSDictionary dictionaryWithObjectsAndKeys:[attachmentFilePath lastPathComponent], @"name",
                                        base64Data, @"data",
                                        mimeType, @"content_type", nil]];
                
            }
            
        }

        if([attachments count]>0) [ticket setObject:attachments forKey:@"attachments"];
        
    }

#endif
    
    [jsonRoot setObject:ticket forKey:@"ticket"];
    
    return [[self class] postPath:path
                         withJSON:jsonRoot
                           target:delegate
                         selector:@selector(didCreateTicket:)
                          rootKey:@"ticket"];
    
}

#ifdef UV_FILE_UPLOADS
+ (NSString*) fileMIMEType:(NSString*) file {
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)[file pathExtension], NULL);
    CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    return [(NSString *)MIMEType autorelease];
}
#endif

@end
