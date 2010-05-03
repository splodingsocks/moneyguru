/* 
Copyright 2010 Hardcoded Software (http://www.hardcoded.net)

This software is licensed under the "HS" License as described in the "LICENSE" file, 
which should be included with this package. The terms are also available at 
http://www.hardcoded.net/licenses/hs_license
*/

#import "MGMainWindow.h"
#import "Utils.h"
#import "MGConst.h"
#import "NSEventAdditions.h"

@implementation MGMainWindow
- (id)initWithDocument:(MGDocument *)document
{
    self = [super initWithNibName:@"MainWindow" pyClassName:@"PyMainWindow" pyParent:[document py]];
    [self setDocument:document];
    [self restoreState];
    accountProperties = [[MGAccountProperties alloc] initWithParent:self];
    transactionPanel = [[MGTransactionInspector alloc] initWithParent:self];
    massEditionPanel = [[MGMassEditionPanel alloc] initWithParent:self];
    schedulePanel = [[MGSchedulePanel alloc] initWithParent:self];
    budgetPanel = [[MGBudgetPanel alloc] initWithParent:self];
    /* We autorelease the views because their reference is kept by the subviews array */
    MGNetWorthView *netWorthView = [[[MGNetWorthView alloc] initWithPyParent:py] autorelease];
    MGProfitView *profitView = [[[MGProfitView alloc] initWithPyParent:py] autorelease];
    MGTransactionView *transactionView = [[[MGTransactionView alloc] initWithPyParent:py] autorelease];
    MGAccountView *accountView = [[[MGAccountView alloc] initWithPyParent:py] autorelease];
    MGScheduleView *scheduleView = [[[MGScheduleView alloc] initWithPyParent:py] autorelease];
    MGBudgetView *budgetView = [[[MGBudgetView alloc] initWithPyParent:py] autorelease];
    searchField = [[MGSearchField alloc] initWithPyParent:py];
    importWindow = [[MGImportWindow alloc] initWithDocument:document];
    [importWindow connect];
    csvOptionsWindow = [[MGCSVImportOptions alloc] initWithDocument:document];
    [csvOptionsWindow connect];
    customDateRangePanel = [[MGCustomDateRangePanel alloc] initWithParent:self];
    accountReassignPanel = [[MGAccountReassignPanel alloc] initWithDocument:document];
    accountLookup = [[MGAccountLookup alloc] initWithPyParent:py];
    completionLookup = [[MGCompletionLookup alloc] initWithPyParent:py];
    dateRangeSelector = [[MGDateRangeSelector alloc] initWithPyParent:py dateRangeView:dateRangeSelectorView];
    
    /* Add views to the tab view */
    NSTabViewItem *item = [[[NSTabViewItem alloc] initWithIdentifier:nil] autorelease];
    [item setView:[netWorthView view]];
    [tabView addTabViewItem:item];
    item = [[[NSTabViewItem alloc] initWithIdentifier:nil] autorelease];
    [item setView:[profitView view]];
    [tabView addTabViewItem:item];
    item = [[[NSTabViewItem alloc] initWithIdentifier:nil] autorelease];
    [item setView:[transactionView view]];
    [tabView addTabViewItem:item];
    item = [[[NSTabViewItem alloc] initWithIdentifier:nil] autorelease];
    [item setView:[accountView view]];
    [tabView addTabViewItem:item];
    item = [[[NSTabViewItem alloc] initWithIdentifier:nil] autorelease];
    [item setView:[scheduleView view]];
    [tabView addTabViewItem:item];
    item = [[[NSTabViewItem alloc] initWithIdentifier:nil] autorelease];
    [item setView:[budgetView view]];
    [tabView addTabViewItem:item];
    subviews = [[NSArray arrayWithObjects:netWorthView, profitView, transactionView, accountView,
        scheduleView, budgetView, nil] retain];
    
    // Setup the toolbar
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:MGMainToolbarIdentifier] autorelease];
    [toolbar setDelegate:self];
    [[self window] setToolbar:toolbar];
    
    NSArray *children = [NSArray arrayWithObjects:[netWorthView py], [profitView py],
        [transactionView py], [accountView py], [scheduleView py], [budgetView py],
        [accountProperties py], [transactionPanel py],  [massEditionPanel py], [schedulePanel py],
        [budgetPanel py], [customDateRangePanel py], [accountLookup py], [completionLookup py],
        [dateRangeSelector py], nil];
    [[self py] setChildren:children];
    [[self py] connect];
    [searchField connect];
    return self;
}

- (void)dealloc
{
    [transactionPanel release];
    [massEditionPanel release];
    [schedulePanel release];
    [accountProperties release];
    [searchField release];
    [importWindow release];
    [csvOptionsWindow release];
    [customDateRangePanel release];
    [accountReassignPanel release];
    [accountLookup release];
    [dateRangeSelector release];
    [subviews release];
    [super dealloc];
}

- (PyMainWindow *)py
{
    return (PyMainWindow *)py;
}

- (MGDocument *)document
{
    return (MGDocument *)[super document];
}

- (void)keyDown:(NSEvent *)event 
{
    if (![self dispatchSpecialKeys:event])
	{
        [super keyDown:event];
	}
}

/* Private */
- (BOOL)dispatchSpecialKeys:(NSEvent *)event
{
    SEL action = nil;
    if ([event modifierKeysFlags] == (NSCommandKeyMask | NSShiftKeyMask))
    {
        if ([event isLeft])
            action = @selector(showPreviousView:);
        else if ([event isRight])
            action = @selector(showNextView:);
    }
    else if ([event modifierKeysFlags] == NSCommandKeyMask)
    {
        if ([event isLeft])
            action = @selector(navigateBack:);
        else if ([event isRight])
            action = @selector(showSelectedAccount:);
    }
    if ((action != nil) && ([self validateAction:action]))
        [self performSelector:action withObject:self];
    return action != nil;
}

- (BOOL)validateAction:(SEL)action
{
    if (action == @selector(newGroup:))
        return [top isKindOfClass:[MGNetWorthView class]] || [top isKindOfClass:[MGProfitView class]];
    else if ((action == @selector(moveUp:)) ||
             (action == @selector(moveDown:)) ||
             (action == @selector(duplicateItem:)) ||
             (action == @selector(makeScheduleFromSelected:)))
        return [top isKindOfClass:[MGTransactionView class]] || [top isKindOfClass:[MGAccountView class]];
    else if (action == @selector(toggleEntriesReconciled:))
        return [top isKindOfClass:[MGAccountView class]] && [(MGAccountView *)top inReconciliationMode];
    else if (action == @selector(showNextView:))
        return [[self py] currentViewIndex] < [[self py] viewCount]-1;
    else if (action == @selector(showPreviousView:))
        return [[self py] currentViewIndex] > 0;
    else if (action == @selector(showEntryTable:))
        return [[self py] canSelectEntryTable];
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
        return [[dateRangeSelector py] canNavigate];
    return YES;
}


/* Actions */

- (IBAction)delete:(id)sender
{
    [[self py] deleteItem];
}

- (IBAction)duplicateItem:(id)sender
{
    [[self py] duplicateItem];
}

- (IBAction)editItemInfo:(id)sender
{
    [[self py] editItem];
}

- (IBAction)jumpToAccount:(id)sender
{
    [[self py] jumpToAccount];
}

- (IBAction)makeScheduleFromSelected:(id)sender
{
    [[self py] makeScheduleFromSelected];
}

- (IBAction)moveDown:(id)sender
{
    [[self py] moveDown];
}

- (IBAction)moveUp:(id)sender
{
    [[self py] moveUp];
}

- (IBAction)navigateBack:(id)sender
{
    [[self py] navigateBack];
}

- (IBAction)newGroup:(id)sender
{
    [[self py] newGroup];
}

- (IBAction)newItem:(id)sender
{
    [[self py] newItem];
}

- (IBAction)search:(id)sender
{
    [[self window] makeFirstResponder:[searchField view]];
}

- (IBAction)selectMonthRange:(id)sender
{
    [[dateRangeSelector py] selectMonthRange];
}

- (IBAction)selectNextDateRange:(id)sender
{
    [[dateRangeSelector py] selectNextDateRange];
}

- (IBAction)selectPrevDateRange:(id)sender
{
    [[dateRangeSelector py] selectPrevDateRange];
}

- (IBAction)selectTodayDateRange:(id)sender
{
    [[dateRangeSelector py] selectTodayDateRange];
}

- (IBAction)selectQuarterRange:(id)sender
{
    [[dateRangeSelector py] selectQuarterRange];
}

- (IBAction)selectYearRange:(id)sender
{
    [[dateRangeSelector py] selectYearRange];
}

- (IBAction)selectYearToDateRange:(id)sender
{
    [[dateRangeSelector py] selectYearToDateRange];
}

- (IBAction)selectRunningYearRange:(id)sender
{
    [[dateRangeSelector py] selectRunningYearRange];
}

- (IBAction)selectAllTransactionsRange:(id)sender
{
    [[dateRangeSelector py] selectAllTransactionsRange];
}

- (IBAction)selectCustomDateRange:(id)sender
{
    [[dateRangeSelector py] selectCustomDateRange];
}

- (IBAction)selectSavedCustomRange:(id)sender
{
    NSInteger slot = [(NSMenuItem *)sender tag] - MGCustomSavedRangeStart;
    [[dateRangeSelector py] selectSavedRange:slot];
}

- (IBAction)showBalanceSheet:(id)sender
{
    [[self py] selectBalanceSheet];
}

- (IBAction)showIncomeStatement:(id)sender
{
    [[self py] selectIncomeStatement];
}

- (IBAction)showTransactionTable:(id)sender
{
    [[self py] selectTransactionTable];
}

- (IBAction)showEntryTable:(id)sender
{
    [[self py] selectEntryTable];
}

- (IBAction)showScheduleTable:(id)sender
{
    [[self py] selectScheduleTable];
}

- (IBAction)showBudgetTable:(id)sender
{
    [[self py] selectBudgetTable];
}

- (IBAction)showNextView:(id)sender
{
    [[self py] selectNextView];
}

- (IBAction)showPreviousView:(id)sender
{
    [[self py] selectPreviousView];
}

- (IBAction)showSelectedAccount:(id)sender
{
    [[self py] showAccount];
}

- (IBAction)toggleEntriesReconciled:(id)sender
{
    [(MGAccountView *)top toggleReconciled];
}

- (IBAction)toggleReconciliationMode:(id)sender
{
    [(MGAccountView *)top toggleReconciliationMode];
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

/* Delegate */
- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self saveState];
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
            NSToolbarFlexibleSpaceItemIdentifier, 
            MGBalanceSheetToolbarItemIdentifier,
            MGIncomeStatementToolbarItemIdentifier,
            MGTransactionsToolbarItemIdentifier,
            MGEntriesToolbarItemIdentifier,
            MGSchedulesToolbarItemIdentifier,
            MGBudgetToolbarItemIdentifier,
            MGDateRangeToolbarItemIdentifier, 
            MGSearchFieldToolbarItemIdentifier, 
            nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    return [NSArray arrayWithObjects:
            MGBalanceSheetToolbarItemIdentifier,
            MGIncomeStatementToolbarItemIdentifier,
            MGTransactionsToolbarItemIdentifier,
            MGEntriesToolbarItemIdentifier,
            MGSchedulesToolbarItemIdentifier,
            MGBudgetToolbarItemIdentifier,
            NSToolbarFlexibleSpaceItemIdentifier,
            MGSearchFieldToolbarItemIdentifier,
            nil];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar;
{
    return [NSArray arrayWithObjects:MGBalanceSheetToolbarItemIdentifier,
                                     MGIncomeStatementToolbarItemIdentifier,
                                     MGTransactionsToolbarItemIdentifier,
                                     MGEntriesToolbarItemIdentifier, 
                                     MGSchedulesToolbarItemIdentifier,
                                     MGBudgetToolbarItemIdentifier, nil];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier 
 willBeInsertedIntoToolbar:(BOOL)inserted
{
    if ([itemIdentifier isEqual:MGSearchFieldToolbarItemIdentifier])
    {
        NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
        [toolbarItem setLabel: @"Filter"];
        [toolbarItem setView:[searchField view]];
        [toolbarItem setMinSize:[[searchField view] frame].size];
        [toolbarItem setMaxSize:[[searchField view] frame].size];
        return toolbarItem;
    }
    else if ([itemIdentifier isEqual:MGBalanceSheetToolbarItemIdentifier])
    {
        NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
        [toolbarItem setLabel:@"Net Worth"];
        [toolbarItem setImage:[NSImage imageNamed:@"balance_sheet_48"]];
        [toolbarItem setToolTip:@"Show the Balance Sheet"];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(showBalanceSheet:)];
        return toolbarItem;
    }
    else if ([itemIdentifier isEqual:MGIncomeStatementToolbarItemIdentifier])
    {
        NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
        [toolbarItem setLabel:@"Profit/Loss"];
        [toolbarItem setImage:[NSImage imageNamed:@"income_statement_48"]];
        [toolbarItem setToolTip:@"Show the Income Statement"];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(showIncomeStatement:)];
        return toolbarItem;
    }
    else if ([itemIdentifier isEqual:MGTransactionsToolbarItemIdentifier])
    {
        NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
        [toolbarItem setLabel:@"Transactions"];
        [toolbarItem setImage:[NSImage imageNamed:@"transaction_table_48"]];
        [toolbarItem setToolTip:@"Edit your transactions"];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(showTransactionTable:)];
        return toolbarItem;
    }
    else if ([itemIdentifier isEqual:MGEntriesToolbarItemIdentifier])
    {
        NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
        [toolbarItem setLabel:@"Account"];
        [toolbarItem setImage:[NSImage imageNamed:@"entry_table_48"]];
        [toolbarItem setToolTip:@"Edit the selected account's entries"];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(showEntryTable:)];
        return toolbarItem;
    }
    else if ([itemIdentifier isEqual:MGSchedulesToolbarItemIdentifier])
    {
        NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
        [toolbarItem setLabel:@"Schedules"];
        [toolbarItem setImage:[NSImage imageNamed:@"schedules_48"]];
        [toolbarItem setToolTip:@"Edit your scheduled transactions"];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(showScheduleTable:)];
        return toolbarItem;
    }
    else if ([itemIdentifier isEqual:MGBudgetToolbarItemIdentifier])
    {
        NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
        [toolbarItem setLabel:@"Budgets"];
        [toolbarItem setImage:[NSImage imageNamed:@"budget_48"]];
        [toolbarItem setToolTip:@"Edit your budgets"];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(showBudgetTable:)];
        return toolbarItem;
    }
    return nil;
}

- (BOOL)validateMenuItem:(NSMenuItem *)aItem
{
    if ([aItem tag] == MGNewItemMenuItem)
    {
        NSString *title = @"New Item";
        if ([top isKindOfClass:[MGNetWorthView class]] || [top isKindOfClass:[MGProfitView class]])
            title = @"New Account";
        else if ([top isKindOfClass:[MGTransactionView class]] || [top isKindOfClass:[MGAccountView class]])
            title = @"New Transaction";
        else if ([top isKindOfClass:[MGScheduleView class]])
            title = @"New Schedule";
        else if ([top isKindOfClass:[MGBudgetView class]])
            title = @"New Budget";
        [aItem setTitle:title];
    }
    return [self validateUserInterfaceItem:aItem];
}

- (BOOL)validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem >)aItem
{
    return [self validateAction:[aItem action]];
}

/* Callbacks for python */
- (void)changeSelectedView
{
    NSInteger index = [[self py] currentViewIndex];
    [tabView selectTabViewItemAtIndex:index];
    top = [subviews objectAtIndex:index];
    NSString *ident = @"";
    switch (index) {
        case 0: ident = MGBalanceSheetToolbarItemIdentifier; break;
        case 1: ident = MGIncomeStatementToolbarItemIdentifier; break;
        case 2: ident = MGTransactionsToolbarItemIdentifier; break;
        case 3: ident = MGEntriesToolbarItemIdentifier; break;
        case 4: ident = MGSchedulesToolbarItemIdentifier; break;
        case 5: ident = MGBudgetToolbarItemIdentifier; break;
    }
    [[[self window] toolbar] setSelectedItemIdentifier:ident];
}

- (void)showAccountReassignPanel
{
    [accountReassignPanel load];
    [NSApp beginSheet:[accountReassignPanel window] modalForWindow:[self window] modalDelegate:self 
        didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];
}

- (void)showMessage:(NSString *)aMessage
{
    NSAlert *a = [NSAlert alertWithMessageText:aMessage defaultButton:nil alternateButton:nil
        otherButton:nil informativeTextWithFormat:@""];
    [a beginSheetModalForWindow:[self window] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}
@end
