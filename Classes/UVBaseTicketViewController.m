//
//  UVBaseTicketViewController.m
//  UserVoice
//
//  Created by Austin Taylor on 10/30/12.
//  Copyright (c) 2012 UserVoice Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "UVBaseTicketViewController.h"
#import "UVSession.h"
#import "UVArticle.h"
#import "UVSuggestion.h"
#import "UVArticleViewController.h"
#import "UVSuggestionDetailsViewController.h"
#import "UVNewSuggestionViewController.h"
#import "UVCustomFieldValueSelectViewController.h"
#import "UVStylesheet.h"
#import "UVCustomField.h"
#import "UVUser.h"
#import "UVClientConfig.h"
#import "UVConfig.h"
#import "UVTicket.h"
#import "UVForum.h"
#import "UVKeyboardUtils.h"
#import "UVWelcomeViewController.h"
#import "UVBabayaga.h"

@implementation UVBaseTicketViewController

@synthesize emailField;
@synthesize nameField;
@synthesize selectedCustomFieldValues;
@synthesize initialText;
@synthesize textView;

- (id)initWithText:(NSString *)theText {
    if (self = [self init]) {
        if (theText)
            self.text = theText;
    }
    return self;
}

- (id)init {
    if (self = [super init]) {
        self.selectedCustomFieldValues = [NSMutableDictionary dictionaryWithDictionary:[UVSession currentSession].config.customFields];
        self.articleHelpfulPrompt = NSLocalizedStringFromTable(@"Do you still want to contact us?", @"UserVoice", nil);
        self.articleReturnMessage = NSLocalizedStringFromTable(@"Yes, go to my message", @"UserVoice", nil);
    }
    return self;
}

- (void)dismissKeyboard {
}

- (BOOL)validateCustomFields {
    for (UVCustomField *field in [UVSession currentSession].clientConfig.customFields) {
        if ([field isRequired]) {
            NSString *value = [selectedCustomFieldValues valueForKey:field.name];
            if (!value || value.length == 0)
                return NO;
        }
    }
    return YES;
}

- (void)sendButtonTapped {
    [self dismissKeyboard];
    self.userEmail = emailField.text;
    self.userName = nameField.text;
    self.text = textView.text;
    if (![UVSession currentSession].user && emailField.text.length == 0) {
        [self alertError:NSLocalizedStringFromTable(@"Please enter your email address before submitting your ticket.", @"UserVoice", nil)];
    } else if (![self validateCustomFields]) {
        [self alertError:NSLocalizedStringFromTable(@"Please fill out all required fields.", @"UserVoice", nil)];
    } else {
        [self showActivityIndicator];
        [UVTicket createWithMessage:self.text andEmailIfNotLoggedIn:emailField.text andName:nameField.text andCustomFields:selectedCustomFieldValues andDelegate:self];
    }
}

- (void)didCreateTicket:(UVTicket *)theTicket {
    self.text = nil;
    [self hideActivityIndicator];
    [[UVSession currentSession] flash:NSLocalizedStringFromTable(@"Your message has been sent.", @"UserVoice", nil) title:NSLocalizedStringFromTable(@"Success!", @"UserVoice", nil) suggestion:nil];
    [UVBabayaga track:SUBMIT_TICKET];

    [self cleanupInstantAnswersTimer];
    dismissed = YES;
    [self dismissModalViewControllerAnimated:YES];
}

- (void)reloadCustomFieldsTable {
    [tableView reloadData];
}

- (void)selectCustomFieldAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)theTableView {
    [emailField resignFirstResponder];
    UVCustomField *field = [[UVSession currentSession].clientConfig.customFields objectAtIndex:indexPath.row];
    if ([field isPredefined]) {
        UIViewController *next = [[[UVCustomFieldValueSelectViewController alloc] initWithCustomField:field valueDictionary:selectedCustomFieldValues] autorelease];
        self.navigationItem.backBarButtonItem.title = NSLocalizedStringFromTable(@"Back", @"UserVoice", nil);
        [self dismissKeyboard];
        [self.navigationController pushViewController:next animated:YES];
    } else {
        UITableViewCell *cell = [theTableView cellForRowAtIndexPath:indexPath];
        UITextField *textField = (UITextField *)[cell viewWithTag:UV_CUSTOM_FIELD_CELL_TEXT_FIELD_TAG];
        [textField becomeFirstResponder];
    }
}

- (void)nonPredefinedValueChanged:(NSNotification *)notification {
    UITextField *textField = (UITextField *)[notification object];
    UIView *view = textField;
    while (view != nil && ![view isKindOfClass:[UITableViewCell class]]) {
        view = view.superview;
    }
    UITableViewCell *cell = (UITableViewCell *)view;
    view = cell;
    while (view != nil && ![view isKindOfClass:[UITableView class]]) {
        view = view.superview;
    }
    UITableView *table = (UITableView *)view;
    NSIndexPath *path = [table indexPathForCell:cell];
    UVCustomField *field = (UVCustomField *)[[UVSession currentSession].clientConfig.customFields objectAtIndex:path.row];
    [selectedCustomFieldValues setObject:textField.text forKey:field.name];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textViewDidChange:(UVTextView *)theTextEditor {
    self.text = self.textView.text;
    [self searchInstantAnswers:self.text];
}

- (void)setText:(NSString *)theText {
    [theText retain];
    [text release];
    text = theText;

    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:text forKey:@"uv-message-text"];
    [prefs synchronize];
}

- (NSString *)text {
    if (text)
        return text;
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    text = [[prefs stringForKey:@"uv-message-text"] retain];
    return text;
}

- (void)didRetrieveInstantAnswers:(NSArray *)theInstantAnswers {
    if (dismissed)
        return;
    [super didRetrieveInstantAnswers:theInstantAnswers];
}

- (void)initCellForCustomField:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
    UILabel *label = [self addCellLabel:cell];
    label.tag = UV_CUSTOM_FIELD_CELL_LABEL_TAG;
    UILabel *valueLabel = [self addCellValueLabel:cell];
    valueLabel.tag = UV_CUSTOM_FIELD_CELL_VALUE_LABEL_TAG;
    UITextField *textField = [self addCellValueTextField:cell];
    textField.tag = UV_CUSTOM_FIELD_CELL_TEXT_FIELD_TAG;
    textField.delegate = self;
}

- (void)customizeCellForCustomField:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    UVCustomField *field = [[UVSession currentSession].clientConfig.customFields objectAtIndex:indexPath.row];
    UILabel *label = (UILabel *)[cell viewWithTag:UV_CUSTOM_FIELD_CELL_LABEL_TAG];
    UITextField *textField = (UITextField *)[cell viewWithTag:UV_CUSTOM_FIELD_CELL_TEXT_FIELD_TAG];
    UILabel *valueLabel = (UILabel *)[cell viewWithTag:UV_CUSTOM_FIELD_CELL_VALUE_LABEL_TAG];
    label.text = [field isRequired] ? [NSString stringWithFormat:@"%@*", field.name] : field.name;
    cell.accessoryType = [field isPredefined] ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    textField.enabled = [field isPredefined] ? NO : YES;
    cell.selectionStyle = [field isPredefined] ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone;
    valueLabel.hidden = ![field isPredefined];
    textField.hidden = [field isPredefined];
    if ([selectedCustomFieldValues objectForKey:field.name]) {
        valueLabel.text = [selectedCustomFieldValues objectForKey:field.name];
        valueLabel.textColor = [UIColor blackColor];
    } else {
        valueLabel.text = NSLocalizedStringFromTable(@"select", @"UserVoice", nil);
        valueLabel.textColor = [UIColor colorWithRed:0.78f green:0.78f blue:0.80f alpha:1.0f];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(nonPredefinedValueChanged:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:textField];
}

- (void)initCellForEmail:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
    self.emailField = [self customizeTextFieldCell:cell label:NSLocalizedStringFromTable(@"Email", @"UserVoice", nil) placeholder:NSLocalizedStringFromTable(@"(required)", @"UserVoice", nil)];
    self.emailField.keyboardType = UIKeyboardTypeEmailAddress;
    self.emailField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.emailField.text = self.userEmail;
}

- (void)initCellForName:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
    self.nameField = [self customizeTextFieldCell:cell label:NSLocalizedStringFromTable(@"Name", @"UserVoice", nil) placeholder:NSLocalizedStringFromTable(@"“Anonymous”", @"UserVoice", nil)];
    self.nameField.text = self.userName;
}

- (void)initNavigationItem {
    [super initNavigationItem];
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Cancel", @"UserVoice", nil)
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(dismiss)] autorelease];
}

- (void)dismiss {
    [self cleanupInstantAnswersTimer];
    dismissed = YES;
    if ([self shouldLeaveViewController]) {
        if ([UVSession currentSession].isModal && firstController)
            [self dismissUserVoice];
        else
            [self dismissModalViewControllerAnimated:YES];
    }
}

- (void)showSaveActionSheet {
    UIActionSheet *actionSheet = [[[UIActionSheet alloc] initWithTitle:nil
                                                              delegate:self
                                                     cancelButtonTitle:NSLocalizedStringFromTable(@"Cancel", @"UserVoice", nil)
                                                destructiveButtonTitle:NSLocalizedStringFromTable(@"Don't save", @"UserVoice", nil)
                                                     otherButtonTitles:NSLocalizedStringFromTable(@"Save draft", @"UserVoice", nil), nil] autorelease];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [actionSheet showFromBarButtonItem:self.navigationItem.leftBarButtonItem animated:YES];
    } else {
        [actionSheet showInView:self.view];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0)
        self.text = nil;
    if (buttonIndex == 0 || buttonIndex == 1) {
        readyToPopView = YES;
        [self dismiss];
    }
}

- (BOOL)shouldLeaveViewController {
    BOOL textChanged = self.text && [self.text length] > 0 && ![self.initialText isEqualToString:self.text];
    if (readyToPopView || !textChanged)
        return YES;
    [self showSaveActionSheet];
    return NO;
}

- (void)dismissUserVoice {
    if ([self shouldLeaveViewController])
        [super dismissUserVoice];
}

- (void)loadView {
    [super loadView];
    self.initialText = self.text;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.textView = nil;
    self.emailField = nil;
    self.nameField = nil;
    self.selectedCustomFieldValues = nil;
    self.initialText = nil;
    [text release];
    text = nil;
    [super dealloc];
}

#pragma mark - UITableViewDelegate

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    [NSException raise:@"Not implemented" format:@"Subclasses of UVBaseTicketViewController must implement tableView:cellForRowAtIndexPath:"];
    return nil;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    [NSException raise:@"Not implemented" format:@"Subclasses of UVBaseTicketViewController must implement tableView:numberOfRowsInSection:"];
    return 0;
}

@end
