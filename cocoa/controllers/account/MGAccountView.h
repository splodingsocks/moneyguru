/* 
Copyright 2013 Hardcoded Software (http://www.hardcoded.net)

This software is licensed under the "BSD" License as described in the "LICENSE" file, 
which should be included with this package. The terms are also available at 
http://www.hardcoded.net/licenses/bsd_license
*/

#import <Cocoa/Cocoa.h>
#import "PyAccountView.h"
#import "MGBaseView.h"
#import "MGTableView.h"
#import "AMButtonBar.h"
#import "MGEntryTable.h"
#import "MGFilterBar.h"
#import "MGBalanceGraph.h"
#import "MGBarGraph.h"

@interface MGAccountView : MGBaseView <NSSplitViewDelegate>
{
    NSSplitView *splitView;
    MGTableView *tableView;
    AMButtonBar *filterBarView;
    NSButton *reconciliationModeButton;
    
    MGEntryTable *entryTable;
    MGFilterBar *filterBar;
    MGBalanceGraph *balanceGraph;
    MGBarGraph *barGraph;
    NSView *graphView;
    BOOL graphCollapsed;
    CGFloat graphCollapseHeight;
}

@property (readwrite, retain) NSSplitView *splitView;
@property (readwrite, retain) MGTableView *tableView;
@property (readwrite, retain) AMButtonBar *filterBarView;
@property (readwrite, retain) NSButton *reconciliationModeButton;

- (id)initWithPyRef:(PyObject *)aPyRef;
- (PyAccountView *)model;

/* Public */
- (id)fieldEditorForObject:(id)asker;
- (BOOL)canToggleReconciliationMode;
- (BOOL)inReconciliationMode;
- (void)toggleReconciliationMode;
- (void)toggleReconciled;

/* model --> view */
- (void)refreshReconciliationButton;
- (void)showLineGraph;
- (void)showBarGraph;
@end