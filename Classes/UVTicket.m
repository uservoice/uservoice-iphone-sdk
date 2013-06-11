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
#import "UVCustomField.h"
#import "UVSession.h"
#import "UVConfig.h"
#import "UVJsonWriter.h"

#include "Base64Transcoder.h"

//Required for detecting content type
#import <MobileCoreServices/MobileCoreServices.h>

@interface UVTicket()

+ (NSString*) fileMIMEType:(NSString*) file;

@end

@implementation UVTicket

+ (id)createWithMessage:(NSString *)message
  andEmailIfNotLoggedIn:(NSString *)email
                andName:(NSString *)name
        andCustomFields:(NSDictionary *)fields
            andDelegate:(id)delegate {
    NSString *path = [self apiPath:@"/tickets.json"];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
        message == nil ? @"" : message, @"ticket[message]",
        email   == nil ? @"" : email,   @"email",
        name    == nil ? @"" : name,    @"display_name",
        nil];
    
    for (NSString *scope in [UVSession currentSession].externalIds) {
        NSString *identifier = [[UVSession currentSession].externalIds valueForKey:scope];
        [params setObject:identifier forKey:[NSString stringWithFormat:@"created_by[external_ids][%@]", scope]];
    }

    NSDictionary *defaultFields = [UVSession currentSession].config.customFields;
    for (NSString *name in [defaultFields keyEnumerator]) {
        [params setObject:[defaultFields objectForKey:name] forKey:[NSString stringWithFormat:@"ticket[custom_field_values][%@]", name]];
    }

    for (NSString *name in [fields keyEnumerator]) {
        [params setObject:[fields objectForKey:name] forKey:[NSString stringWithFormat:@"ticket[custom_field_values][%@]", name]];
    }

    if ([UVSession currentSession].config.extraTicketInfo != nil) {
        NSString *messageText = [NSString stringWithFormat:@"%@\n\n%@", message, [UVSession currentSession].config.extraTicketInfo];
        [params setObject:messageText forKey:@"ticket[message]"];
    }

    if ([UVSession currentSession].config.attachmentFilePaths != nil) {
        
        //Loop over the attachment files so see which exists
        
        for(NSString *attachmentFilePath in [UVSession currentSession].config.attachmentFilePaths){

            NSInteger index = 0;
            
            if([[NSFileManager defaultManager] fileExistsAtPath:attachmentFilePath]){

                NSData *fileData = [[NSData alloc] initWithContentsOfFile:attachmentFilePath];
                
                Byte inputData[[fileData length]];
                [fileData getBytes:inputData];
                size_t inputDataSize = (size_t)[fileData length];
                size_t outputDataSize = UVEstimateBas64EncodedDataSize(inputDataSize);
                char outputData[outputDataSize];
                
                UVBase64EncodeData(inputData, inputDataSize, outputData, &outputDataSize);
                
                NSString *base64Data = [[NSString alloc] initWithBytes:outputData length:outputDataSize encoding:NSUTF8StringEncoding];

                UVJsonWriter *jsonWriter = [UVJsonWriter new];
                
                [params setObject:[jsonWriter stringWithFragment:[attachmentFilePath lastPathComponent]]
                           forKey:[NSString stringWithFormat:@"ticket[attachments][%i][name]", index]];
             
                [params setObject:[jsonWriter stringWithFragment:base64Data]
                           forKey:[NSString stringWithFormat:@"ticket[attachments][%i][data]", index]];

                [params setObject:[jsonWriter stringWithFragment:[self fileMIMEType:attachmentFilePath]]
                           forKey:[NSString stringWithFormat:@"ticket[attachments][%i][content_type]", index]];
             
                index++;

            }
                        
        }
        
    }

    return [[self class] postPath:path
                       withParams:params
                           target:delegate
                         selector:@selector(didCreateTicket:)
                          rootKey:@"ticket"];
}

+ (NSString*) fileMIMEType:(NSString*) file {
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)[file pathExtension], NULL);
    CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    return [(NSString *)MIMEType autorelease];
}
@end
