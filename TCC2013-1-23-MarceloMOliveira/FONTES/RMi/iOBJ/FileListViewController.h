//
//  FileListViewController.h
//  RMi
//
//  Created by Marcelo da Mata.
//
//

#import <UIKit/UIKit.h>

@class FileListViewController;

@protocol FileListViewControllerDelegate <NSObject>

@optional
- (void)fileList:(FileListViewController *)fileList selectedFile:(NSString *)file;
- (void)fileListWillClose:(FileListViewController *)fileList;
- (void)fileListDidClose:(FileListViewController *)fileList;

@end

@interface FileListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) IBOutlet UITableView *filesTableView;
@property (nonatomic, weak) id<FileListViewControllerDelegate> delegate;
@property (nonatomic, strong) NSString *selectedFile;

- (IBAction)cancel:(id)sender;

@end
