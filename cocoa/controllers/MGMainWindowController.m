/* 
Copyright 2011 Hardcoded Software (http://www.hardcoded.net)

This software is licensed under the "BSD" License as described in the "LICENSE" file, 
which should be included with this package. The terms are also available at 
http://www.hardcoded.net/licenses/bsd_license
*/

#import "MGMainWindowController.h"
#import "MGConst.h"
#import "Utils.h"

@implementation MGMainWindowController
- (id)initWithDocument:(MGDocument *)document
{
    self = [super initWithWindowNibName:@"MainWindow"];
    model = [[PyMainWindow alloc] initWithDocument:[[document model] pyRef]];
    [model bindCallback:createCallback(@"MainWindowView", self)];
    [self setDocument:document];
    /* Put a cute iTunes-like bottom bar */
    [[self window] setContentBorderThickness:28 forEdge:NSMinYEdge];
    [self restoreState];
    accountProperties = [[MGAccountProperties alloc] initWithParent:self];
    transactionPanel = [[MGTransactionInspector alloc] initWithParent:self];
    massEditionPanel = [[MGMassEditionPanel alloc] initWithParent:self];
    schedulePanel = [[MGSchedulePanel alloc] initWithParent:self];
    budgetPanel = [[MGBudgetPanel alloc] initWithParent:self];
    exportPanel = [[MGExportPanel alloc] initWithParent:self];
    netWorthView = [[MGNetWorthView alloc] initWithPyRef:[[self model] nwview]];
    profitView = [[MGProfitView alloc] initWithPyRef:[[self model] pview]];
    transactionView = [[MGTransactionView alloc] initWithPyRef:[[self model] tview]];
    accountView = [[MGAccountView alloc] initWithPyRef:[[self model] aview]];
    scheduleView = [[MGScheduleView alloc] initWithPyRef:[[self model] scview]];
    budgetView = [[MGBudgetView alloc] initWithPyRef:[[self model] bview]];
    cashculatorView = [[MGCashculatorView alloc] initWithPyRef:[[self model] ccview]];
    ledgerView = [[MGGeneralLedgerView alloc] initWithPyRef:[[self model] glview]];
    docpropsView = [[MGDocPropsView alloc] initWithPyRef:[[self model] dpview]];
    emptyView = [[MGEmptyView alloc] initWithPyRef:[[self model] emptyview]];
    searchField = [[MGSearchField alloc] initWithPyRef:[[self model] searchField]];
    importWindow = [[MGImportWindow alloc] initWithDocument:document];
    csvOptionsWindow = [[MGCSVImportOptions alloc] initWithDocument:document];
    customDateRangePanel = [[MGCustomDateRangePanel alloc] initWithParent:self];
    accountReassignPanel = [[MGAccountReassignPanel alloc] initWithParent:self];
    accountLookup = [[MGAccountLookup alloc] initWithPyRef:[[self model] accountLookup]];
    completionLookup = [[MGCompletionLookup alloc] initWithPyRef:[[self model] completionLookup]];
    dateRangeSelector = [[MGDateRangeSelector alloc] initWithPyRef:[[self model] daterangeSelector]];
    subviews = [[NSMutableArray alloc] init];
    
    // Setup the toolbar
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:MGMainToolbarIdentifier] autorelease];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    [toolbar setDelegate:self];
    [[self window] setToolbar:toolbar];
    
    [[self model] connect];
    /* Don't set the delegate in the XIB or else delegates methods are called too soon and cause
       crashes.
    */
    [tabBar setShowAddTabButton:YES];
    [tabBar setSizeCellsToFit:YES];
    [tabBar setCellMinWidth:130];
    [tabBar setDelegate:self];
    [[tabBar addTabButton] setTarget:self];
    [[tabBar addTabButton] setAction:@selector(newTab:)];
    return self;
}

- (void)dealloc
{
    [transactionPanel release];
    [massEditionPanel release];
    [schedulePanel release];
    [accountProperties release];
    [budgetPanel release];
    [exportPanel release];
    [netWorthView release];
    [profitView release];
    [accountView release];
    [transactionView release];
    [scheduleView release];
    [budgetView release];
    [cashculatorView release];
    [ledgerView release];
    [docpropsView release];
    [emptyView release];
    [searchField release];
    [importWindow release];
    [csvOptionsWindow release];
    [customDateRangePanel release];
    [accountReassignPanel release];
    [accountLookup release];
    [completionLookup release];
    [dateRangeSelector release];
    [subviews release];
    [model release];
    [super dealloc];
}

- (PyMainWindow *)model
{
    return (PyMainWindow *)model;
}

- (MGDocument *)document
{
    return (MGDocument *)[super document];
}

/* Private */
- (BOOL)validateAction:(SEL)action
{
    if ((action == @selector(newGroup:)) || (action == @selector(toggleExcluded:)))
        return [top isKindOfClass:[MGNetWorthView class]] || [top isKindOfClass:[MGProfitView class]];
    else if ((action == @selector(moveUp:)) ||
             (action == @selector(moveDown:)) ||
             (action == @selector(duplicateItem:)) ||
             (action == @selector(makeScheduleFromSelected:)))
        return [top isKindOfClass:[MGTransactionView class]] || [top isKindOfClass:[MGAccountView class]];
    else if (action == @selector(toggleEntriesReconciled:))
        return [top isKindOfClass:[MGAccountView class]] && [(MGAccountView *)top inReconciliationMode];
    else if (action == @selector(showNextView:))
        return [[self model] currentPaneIndex] < [[self model] paneCount]-1;
    else if (action == @selector(showPreviousView:))
        return [[self model] currentPaneIndex] > 0;
    else if (action == @selector(showSelectedAccount:)) {
        if ([top isKindOfClass:[MGNetWorthView class]] || [top isKindOfClass:[MGProfitView class]])
            return [(id)top canShowSelectedAccount];
        else
            return [top isKindOfClass:[MGTransactionView class]] || [top isKindOfClass:[MGAccountView class]];
    }
    else if (action == @selector(navigateBack:))
        return [top isKindOfClass:[MGAccountView class]];
    else if (action == @selector(toggleReconciliationMode:))
        return [top isKindOfClass:[MGAccountView class]] && [(MGAccountView *)top canToggleReconciliationMode];
    else if ((action == @selector(selectPrevDateRange:)) || (action == @selector(selectNextDateRange:))
        || (action == @selector(selectTodayDateRange:)))
        return [[dateRangeSelector model] canNavigate];
    return YES;
}

- (NSMenu *)buildColumnsMenu
{
    NSArray *menuItems = [[self model] columnMenuItems];
    if (menuItems == nil) {
        return nil;
    }
    NSMenu *m = [[NSMenu alloc] initWithTitle:@""];
    for (NSInteger i=0; i < [menuItems count]; i++) {
        NSArray *pair = [menuItems objectAtIndex:i];
        NSString *display = [pair objectAtIndex:0];
        BOOL marked = n2b([pair objectAtIndex:1]);
        NSMenuItem *mi = [m addItemWithTitle:display action:@selector(columnMenuClick:) keyEquivalent:@""];
        [mi setTarget:self];
        [mi setState:marked ? NSOnState : NSOffState];
        [mi setTag:i];
    }
    return [m autorelease];
}

/* Actions */
- (IBAction)columnMenuClick:(id)sender
{
    NSMenuItem *mi = (NSMenuItem *)sender;
    NSInteger index = [mi tag];
    [[self model] toggleColumnMenuItemAtIndex:index];
}

- (IBAction)delete:(id)sender
{
    [[self model] deleteItem];
}

- (IBAction)duplicateItem:(id)sender
{
    [[self model] duplicateItem];
}

- (IBAction)editItemInfo:(id)sender
{
    [[self model] editItem];
}

- (IBAction)itemSegmentClicked:(id)sender
{
    NSInteger index = [(NSSegmentedControl *)sender selectedSegment];
    if (index == 0) {
        [self newItem:sender];
    }
    else if (index == 1) {
        [self delete:sender];
    }
    else if (index == 2) {
        [self editItemInfo:sender];
    }
}

- (IBAction)jumpToAccount:(id)sender
{
    [[self model] jumpToAccount];
}

- (IBAction)makeScheduleFromSelected:(id)sender
{
    [[self model] makeScheduleFromSelected];
}

- (IBAction)moveSelectionDown:(id)sender
{
    [[self model] moveDown];
}

- (IBAction)moveSelectionUp:(id)sender
{
    [[self model] moveUp];
}

- (IBAction)navigateBack:(id)sender
{
    [[self model] navigateBack];
}

- (IBAction)newGroup:(id)sender
{
    [[self model] newGroup];
}

- (IBAction)newItem:(id)sender
{
    [[self model] newItem];
}

- (IBAction)newTab:(id)sender
{
    [[self model] newTab];
}

- (IBAction)search:(id)sender
{
    [[self window] makeFirstResponder:[searchField view]];
}

- (IBAction)selectMonthRange:(id)sender
{
    [dateRangeSelector selectMonthRange:sender];
}

- (IBAction)selectNextDateRange:(id)sender
{
    [dateRangeSelector selectNextDateRange:sender];
}

- (IBAction)selectPrevDateRange:(id)sender
{
    [dateRangeSelector selectPrevDateRange:sender];
}

- (IBAction)selectTodayDateRange:(id)sender
{
    [dateRangeSelector selectTodayDateRange:sender];
}

- (IBAction)selectQuarterRange:(id)sender
{
    [dateRangeSelector selectQuarterRange:sender];
}

- (IBAction)selectYearRange:(id)sender
{
    [dateRangeSelector selectYearRange:sender];
}

- (IBAction)selectYearToDateRange:(id)sender
{
    [dateRangeSelector selectYearToDateRange:sender];
}

- (IBAction)selectRunningYearRange:(id)sender
{
    [dateRangeSelector selectRunningYearRange:sender];
}

- (IBAction)selectAllTransactionsRange:(id)sender
{
    [dateRangeSelector selectAllTransactionsRange:sender];
}

- (IBAction)selectCustomDateRange:(id)sender
{
    [dateRangeSelector selectCustomDateRange:sender];
}

- (IBAction)selectSavedCustomRange:(id)sender
{
    [dateRangeSelector selectSavedCustomRange:sender];
}

- (IBAction)showBalanceSheet:(id)sender
{
    [[self model] showPaneOfType:MGPaneTypeNetWorth];
}

- (IBAction)showIncomeStatement:(id)sender
{
    [[self model] showPaneOfType:MGPaneTypeProfit];
}

- (IBAction)showTransactionTable:(id)sender
{
    [[self model] showPaneOfType:MGPaneTypeTransaction];
}

- (IBAction)showNextView:(id)sender
{
    [[self model] selectNextView];
}

- (IBAction)showPreviousView:(id)sender
{
    [[self model] selectPreviousView];
}

- (IBAction)showSelectedAccount:(id)sender
{
    [[self model] showAccount];
}

- (IBAction)toggleEntriesReconciled:(id)sender
{
    [(MGAccountView *)top toggleReconciled];
}

- (IBAction)toggleExcluded:(id)sender
{
    [(id)top toggleExcluded];
}

- (IBAction)toggleReconciliationMode:(id)sender
{
    [(MGAccountView *)top toggleReconciliationMode];
}

- (IBAction)toggleAreaVisibility:(id)sender
{
    NSSegmentedControl *sc = (NSSegmentedControl *)sender;
    NSInteger index = [sc selectedSegment];
    if (index == 0) {
        [[self model] toggleAreaVisibility:MGPaneAreaBottomGraph];
    }
    else if (index == 1) {
        [[self model] toggleAreaVisibility:MGPaneAreaRightChart];
    }
    else {
        NSMenu *m = [self buildColumnsMenu];
        if (m != nil) {
            NSRect buttonRect = [sc frame];
            CGFloat lastSegmentWidth = [sc widthForSegment:2];
            NSPoint popupPoint = NSMakePoint(NSMaxX(buttonRect)-lastSegmentWidth, NSMaxY(buttonRect));
            [m popUpMenuPositioningItem:nil atLocation:popupPoint inView:[[self window] contentView]];
        }
    }
}

- (IBAction)toggleGraph:(id)sender
{
    [[self model] toggleAreaVisibility:MGPaneAreaBottomGraph];
}

- (IBAction)togglePieChart:(id)sender
{
    [[self model] toggleAreaVisibility:MGPaneAreaRightChart];
}

- (IBAction)export:(id)sender
{
    [[self model] export];
}

/* Public */

- (void)restoreState
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *frameData = [ud stringForKey:@"MainWindowFrame"];
    if (frameData != nil)
    {
        NSRect frame = NSRectFromString(frameData);
        [[self window] setFrame:frame display:YES];
    }
}

- (void)saveState
{
    NSRect f = [[self window] frame];
    NSString *frameData = NSStringFromRect(f);
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setValue:frameData forKey:@"MainWindowFrame"];
}

- (MGPrintView *)viewToPrint
{
    return [top viewToPrint];
}

- (NSInteger)openedTabCount
{
    return [[self model] paneCount];
}

- (void)closeActiveTab
{
    [[self model] closePaneAtIndex:[[self model] currentPaneIndex]];
}

/* Delegate */
- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
}

- (BOOL)tabView:(NSTabView *)aTabView shouldCloseTabViewItem:(NSTabViewItem *)aTabViewItem
{
    NSInteger index = [tabView indexOfTabViewItem:aTabViewItem];
    [[self model] closePaneAtIndex:index];
    /* We never let the tab bar remove the tab itself. It causes all kind of problems with tab
       syncing. A callback will take care of closing the tab manually.
     */
    return NO;
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)aTabViewItem
{
    NSInteger index = [tabView indexOfTabViewItem:aTabViewItem];
    [[self model] setCurrentPaneIndex:index];
}

- (void)tabView:(NSTabView *)aTabView movedTab:(NSTabViewItem *)aTabViewItem fromIndex:(NSInteger)aFrom toIndex:(NSInteger)aTo
{
    [[self model] movePaneAtIndex:aFrom toIndex:aTo];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self saveState];
    [tabBar setDelegate:nil];
}

- (id)windowWillReturnFieldEditor:(NSWindow *)window toObject:(id)asker
{
    if ([top respondsToSelector:@selector(fieldEditorForObject:)]) {
        return [(id)top fieldEditorForObject:asker];
    }
    return nil;
}

/* Toolbar delegate */
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return [NSArray arrayWithObjects:
            NSToolbarSpaceItemIdentifier,
            NSToolbarFlexibleSpaceItemIdentifier, 
            MGDateRangeToolbarItemIdentifier,
            MGSearchFieldToolbarItemIdentifier, 
            MGBalanceSheetToolbarItemIdentifier,
            MGIncomeStatementToolbarItemIdentifier,
            MGTransactionsToolbarItemIdentifier,
            nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    return [NSArray arrayWithObjects:
            NSToolbarSpaceItemIdentifier,
            NSToolbarFlexibleSpaceItemIdentifier,
            MGDateRangeToolbarItemIdentifier,
            NSToolbarFlexibleSpaceItemIdentifier,
            MGSearchFieldToolbarItemIdentifier,
            nil];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier 
 willBeInsertedIntoToolbar:(BOOL)inserted
{
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
    if ([itemIdentifier isEqual:MGSearchFieldToolbarItemIdentifier]) {
        [toolbarItem setLabel: TR(@"Filter")];
        [toolbarItem setView:[searchField view]];
        [toolbarItem setMinSize:[[searchField view] frame].size];
        [toolbarItem setMaxSize:[[searchField view] frame].size];
    }
    else if ([itemIdentifier isEqual:MGDateRangeToolbarItemIdentifier]) {
        [toolbarItem setLabel: TR(@"Date Range")];
        [toolbarItem setView:[dateRangeSelector view]];
        [toolbarItem setMinSize:[[dateRangeSelector view] frame].size];
        [toolbarItem setMaxSize:[[dateRangeSelector view] frame].size];
    }
    else if ([itemIdentifier isEqual:MGBalanceSheetToolbarItemIdentifier])
    {
        [toolbarItem setLabel:TR(@"Net Worth")];
        [toolbarItem setImage:[NSImage imageNamed:@"balance_sheet_48"]];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(showBalanceSheet:)];
    }
    else if ([itemIdentifier isEqual:MGIncomeStatementToolbarItemIdentifier])
    {
        [toolbarItem setLabel:TR(@"Profit/Loss")];
        [toolbarItem setImage:[NSImage imageNamed:@"income_statement_48"]];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(showIncomeStatement:)];
    }
    else if ([itemIdentifier isEqual:MGTransactionsToolbarItemIdentifier])
    {
        [toolbarItem setLabel:TR(@"Transactions")];
        [toolbarItem setImage:[NSImage imageNamed:@"transaction_table_48"]];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(showTransactionTable:)];
    }
    else {
        toolbarItem = nil;
    }
    return toolbarItem;
}

- (BOOL)validateMenuItem:(NSMenuItem *)aItem
{
    if ([aItem tag] == MGNewItemMenuItem) {
        NSString *title = TR(@"New Item");
        if ([top isKindOfClass:[MGNetWorthView class]] || [top isKindOfClass:[MGProfitView class]])
            title = TR(@"New Account");
        else if ([top isKindOfClass:[MGTransactionView class]] || [top isKindOfClass:[MGAccountView class]])
            title = TR(@"New Transaction");
        else if ([top isKindOfClass:[MGScheduleView class]])
            title = TR(@"New Schedule");
        else if ([top isKindOfClass:[MGBudgetView class]])
            title = TR(@"New Budget");
        [aItem setTitle:title];
    }
    return [self validateUserInterfaceItem:aItem];
}

- (BOOL)validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem >)aItem
{
    return [self validateAction:[aItem action]];
}

/* Callbacks for python */
- (void)changeSelectedPane
{
    NSInteger index = [[self model] currentPaneIndex];
    [tabView selectTabViewItemAtIndex:index];
    top = [subviews objectAtIndex:index];
    [[self window] makeFirstResponder:[top mainResponder]];
}

- (void)refreshPanes
{
    [tabBar setDelegate:nil];
    [subviews removeAllObjects];
    NSInteger paneCount = [[self model] paneCount];
    while ([tabView numberOfTabViewItems] > paneCount) {
        NSTabViewItem *item = [tabView tabViewItemAtIndex:paneCount];
        [tabView removeTabViewItem:item];
    }
    
    for (NSInteger i=0; i<paneCount; i++) {
        NSInteger paneType = [[self model] paneTypeAtIndex:i];
        NSString *label = [[self model] paneLabelAtIndex:i];
        MGBaseView *view = nil;
        NSImage *tabIcon = nil;
        if (paneType == MGPaneTypeNetWorth) {
            view = netWorthView;
            tabIcon = [NSImage imageNamed:@"balance_sheet_16"];
        }
        else if (paneType == MGPaneTypeProfit) {
            view = profitView;
            tabIcon = [NSImage imageNamed:@"income_statement_16"];
        }
        else if (paneType == MGPaneTypeTransaction) {
            view = transactionView;
            tabIcon = [NSImage imageNamed:@"transaction_table_16"];
        }
        else if (paneType == MGPaneTypeAccount) {
            view = accountView;
            tabIcon = [NSImage imageNamed:@"entry_table_16"];
        }
        else if (paneType == MGPaneTypeSchedule) {
            view = scheduleView;
            tabIcon = [NSImage imageNamed:@"schedules_16"];
        }
        else if (paneType == MGPaneTypeBudget) {
            view = budgetView;
            tabIcon = [NSImage imageNamed:@"budget_16"];
        }
        else if (paneType == MGPaneTypeCashculator) {
            view = cashculatorView;
            tabIcon = [NSImage imageNamed:@"cashculator_16"];
        }
        else if (paneType == MGPaneTypeGeneralLedger) {
            view = ledgerView;
            tabIcon = [NSImage imageNamed:@"gledger_16"];
        }
        else if (paneType == MGPaneTypeDocProps) {
            view = docpropsView;
            tabIcon = [NSImage imageNamed:@"gledger_16"];
        }
        else if (paneType == MGPaneTypeEmpty) {
            view = emptyView;
        }
        [subviews addObject:view];
        NSTabViewItem *item;
        if (i < [tabView numberOfTabViewItems]) {
            item = [tabView tabViewItemAtIndex:i];
            [item setLabel:label];
            [item setView:[view view]];
        }
        else {
            item = [[[NSTabViewItem alloc] initWithIdentifier:nil] autorelease];
            [item setLabel:label];
            [item setView:[view view]];
            [tabView addTabViewItem:item];
        }
        /* We use cellForTab instead of cellAtIndex because in some cases (just after a move, for
           instance), the cells are not in sync with the tab items so the indexes might not match.
        */
        PSMTabBarCell *tabCell = [tabBar cellForTab:item];
        [tabCell setIcon:tabIcon];
    }
    [tabBar setDelegate:self];
}

- (void)refreshStatusLine
{
    [statusLabel setStringValue:[[self model] statusLine]];
}

- (void)refreshUndoActions
{
    [[self window] setDocumentEdited:[[self document] isDocumentEdited]];
}

- (void)showMessage:(NSString *)aMessage
{
    NSAlert *a = [NSAlert alertWithMessageText:aMessage defaultButton:nil alternateButton:nil
        otherButton:nil informativeTextWithFormat:@""];
    [a beginSheetModalForWindow:[self window] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

- (void)updateAreaVisibility
{
    NSIndexSet *hiddenAreas = [Utils array2IndexSet:[[self model] hiddenAreas]];
    NSString *imgname = [hiddenAreas containsIndex:MGPaneAreaBottomGraph] ? @"graph_visibility_off_16" : @"graph_visibility_on_16";
    [visibilitySegments setImage:[NSImage imageNamed:imgname] forSegment:0];
    imgname = [hiddenAreas containsIndex:MGPaneAreaRightChart] ? @"piechart_visibility_off_16" : @"piechart_visibility_on_16";
    [visibilitySegments setImage:[NSImage imageNamed:imgname] forSegment:1];
}

- (void)viewClosedAtIndex:(NSInteger)index
{
    NSTabViewItem *item = [tabView tabViewItemAtIndex:index];
    [subviews removeObjectAtIndex:index];
    [tabView removeTabViewItem:item];
}
@end
