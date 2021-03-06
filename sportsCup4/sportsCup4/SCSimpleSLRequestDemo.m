// SCSimpleSLRequestDemo.m
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import "SCSimpleSLRequestDemo.h"
#import "User.h"

@interface SCSimpleSLRequestDemo()
@property (nonatomic) ACAccountStore *accountStore;
@property User *user;
@end

@implementation SCSimpleSLRequestDemo

- (id)init
{
    self = [super init];
    if (self) {
        _accountStore = [[ACAccountStore alloc] init];
    }
    return self;
}

- (BOOL)userHasAccessToTwitter
{
    return [SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter];
}

// https://api.twitter.com/1.1/users/show.json?screen_name=rsarver
- (void)setTwitterUserInfo
{
    //  Step 0: Check that the user has local Twitter accounts
    if ([self userHasAccessToTwitter]) {
        //  Step 1:  Obtain access to the user's Twitter accounts
        ACAccountType *twitterAccountType = [self.accountStore
                                             accountTypeWithAccountTypeIdentifier:
                                             ACAccountTypeIdentifierTwitter];
        [self.accountStore
         requestAccessToAccountsWithType:twitterAccountType
         options:NULL
         completion:^(BOOL granted, NSError *error) {
             if (granted) {
                 //  Step 2:  Create a request
                 NSArray *twitterAccounts =
                 [self.accountStore accountsWithAccountType:twitterAccountType];
                 ACAccount *account = [twitterAccounts lastObject];
                 
                 NSURL *url = [NSURL URLWithString:@"https://api.twitter.com"
                               @"/1.1/users/show.json"];
                 NSDictionary *params = @{@"screen_name" : [account username],
                                          @"include_rts" : @"0",
                                          @"trim_user" : @"1",
                                          @"count" : @"1"};
                 SLRequest *request =
                 [SLRequest requestForServiceType:SLServiceTypeTwitter
                                    requestMethod:SLRequestMethodGET
                                              URL:url
                                       parameters:params];
                 
                 //  Attach an account to the request
                 [request setAccount:[twitterAccounts lastObject]];
                 
                 //  Step 3:  Execute the request
                 [request performRequestWithHandler:^(NSData *responseData,
                                                      NSHTTPURLResponse *urlResponse,
                                                      NSError *error) {
                     if (responseData) {
                         if (urlResponse.statusCode >= 200 && urlResponse.statusCode < 300) {
                             NSError *jsonError;
                             NSDictionary *userinfo =
                             [NSJSONSerialization
                              JSONObjectWithData:responseData
                              options:NSJSONReadingAllowFragments error:&jsonError];

                             [self.user setTwitterHandle:([account username])];
                             [self.user setUserName:([userinfo objectForKey: @"name"])];
                             [self.user setUserAddress:([userinfo objectForKey: @"location"])];
                             [self.user setImage:([UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[userinfo objectForKey: @"profile_image_url"]]]])];
                         }
                         else {
                             // The server did not respond successfully... were we rate-limited?
                             NSLog(@"The response status code is %d", urlResponse.statusCode);
                         }
                     }
                 }];
             }
         }];
    }
}

- (void)fetchTimelineForUser:(NSString *)username
{
    //  Step 0: Check that the user has local Twitter accounts
    if ([self userHasAccessToTwitter]) {
        
        //  Step 1:  Obtain access to the user's Twitter accounts
        ACAccountType *twitterAccountType = [self.accountStore
                                             accountTypeWithAccountTypeIdentifier:
                                             ACAccountTypeIdentifierTwitter];
        [self.accountStore
         requestAccessToAccountsWithType:twitterAccountType
         options:NULL
         completion:^(BOOL granted, NSError *error) {
             if (granted) {
                 //  Step 2:  Create a request
                 NSArray *twitterAccounts =
                 [self.accountStore accountsWithAccountType:twitterAccountType];
                 NSURL *url = [NSURL URLWithString:@"https://api.twitter.com"
                               @"/1.1/statuses/user_timeline.json"];
                 NSDictionary *params = @{@"screen_name" : username,
                                          @"include_rts" : @"0",
                                          @"trim_user" : @"1",
                                          @"count" : @"1"};
                 SLRequest *request =
                 [SLRequest requestForServiceType:SLServiceTypeTwitter
                                    requestMethod:SLRequestMethodGET
                                              URL:url
                                       parameters:params];
                 
                 //  Attach an account to the request
                 [request setAccount:[twitterAccounts lastObject]];
                 
                 //  Step 3:  Execute the request
                 [request performRequestWithHandler:^(NSData *responseData,
                                                      NSHTTPURLResponse *urlResponse,
                                                      NSError *error) {
                     if (responseData) {
                         if (urlResponse.statusCode >= 200 && urlResponse.statusCode < 300) {
                             NSError *jsonError;
                             NSDictionary *timelineData =
                             [NSJSONSerialization
                              JSONObjectWithData:responseData
                              options:NSJSONReadingAllowFragments error:&jsonError];
                             
                             if (timelineData) {
                                 NSLog(@"Timeline Response: %@\n", timelineData);
                             }
                             else {
                                 // Our JSON deserialization went awry
                                 NSLog(@"JSON Error: %@", [jsonError localizedDescription]);
                             }
                         }
                         else {
                             // The server did not respond successfully... were we rate-limited?
                             NSLog(@"The response status code is %d", urlResponse.statusCode);
                         }
                     }
                 }];
             }
             else {
                 // Access was not granted, or an error occurred
                 NSLog(@"%@", [error localizedDescription]);
             }
         }];
    }
}

@end