# Created By: Virgil Dupras
# Created On: 2009-11-01
# Copyright 2013 Hardcoded Software (http://www.hardcoded.net)
# 
# This software is licensed under the "BSD" License as described in the "LICENSE" file, 
# which should be included with this package. The terms are also available at 
# http://www.hardcoded.net/licenses/bsd_license

from PyQt4.QtCore import Qt

from qtlib.column import Column
from ..account_sheet import AccountSheet

class ProfitSheet(AccountSheet):
    COLUMNS = [
        Column('name', 133),
        Column('account_number', 80),
        Column('cash_flow', 100, alignment=Qt.AlignRight),
        Column('last_cash_flow', 100, alignment=Qt.AlignRight),
        Column('delta', 100, alignment=Qt.AlignRight),
        Column('delta_perc', 100),
        Column('budgeted', 100, alignment=Qt.AlignRight),
    ]
    AMOUNT_ATTRS = {'cash_flow', 'last_cash_flow', 'delta', 'delta_perc', 'budgeted'}
    BOLD_ATTRS = {'cash_flow', }
    
