# Created By: Virgil Dupras
# Created On: 2009-11-06
# Copyright 2012 Hardcoded Software (http://www.hardcoded.net)
# 
# This software is licensed under the "BSD" License as described in the "LICENSE" file, 
# which should be included with this package. The terms are also available at 
# http://www.hardcoded.net/licenses/bsd_license

from PyQt4.QtCore import Qt, QPoint
from PyQt4.QtGui import QPainter, QFont, QFontMetrics, QPen, QColor, QBrush, QLinearGradient

from core.gui.graph import PenID
from .chart_view import ChartView

class GraphView(ChartView):
    PADDING = 16
    LINE_WIDTH = 2
    OVERLAY_AXIS_WIDTH = 0.2
    LABEL_FONT_SIZE = 8
    TITLE_FONT_SIZE = 12
    TICKMARKS_LENGTH = 5
    XLABELS_PADDING = 3
    YLABELS_PADDING = 8
    
    def __init__(self, parent=None):
        ChartView.__init__(self, parent)
        self.dataSource = None
        pen = QPen()
        pen.setColor(QColor(20, 158, 11))
        pen.setWidthF(self.LINE_WIDTH)
        self.linePen = pen
        
        gradient = QLinearGradient(0, 0, 0, 1)
        gradient.setCoordinateMode(QLinearGradient.ObjectBoundingMode)
        gradient.setColorAt(0, QColor(93, 188, 86)) # dark green
        gradient.setColorAt(1, QColor(164, 216, 158)) # light green
        self.graphBrush = QBrush(gradient)
        gradient = QLinearGradient(0, 0, 0, 1)
        gradient.setCoordinateMode(QLinearGradient.ObjectBoundingMode)
        gradient.setColorAt(0, Qt.darkGray)
        gradient.setColorAt(1, Qt.lightGray)
        self.graphFutureBrush = QBrush(gradient)
    
    def penForID(self, penId):
        if penId == PenID.AxisOverlay:
            pen = QPen()
            pen.setColor(Qt.darkGray)
            pen.setWidthF(self.OVERLAY_AXIS_WIDTH)
            return pen
    
    def _drawGraph(self, painter, xFactor, yFactor):
        raise NotImplementedError()
    
    def paintEvent(self, event):
        ChartView.paintEvent(self, event)
        if self.dataSource is None:
            return
        painter = QPainter(self)
        painter.setRenderHints(QPainter.Antialiasing|QPainter.TextAntialiasing)
        painter.fillRect(self.rect(), Qt.white)
        ds = self.dataSource
        
        labelsFont = QFont(painter.font())
        labelsFont.setPointSize(self.LABEL_FONT_SIZE)
        labelsFontM = QFontMetrics(labelsFont)
        
        axisPen = QPen(painter.pen())
        axisPen.setColor(Qt.darkGray)
        axisPen.setWidthF(self.LINE_WIDTH)
        
        viewWidth = self.width()
        viewHeight = self.height()
        middleX = viewWidth // 2
        dataWidth = ds.xmax - ds.xmin
        dataHeight = ds.ymax - ds.ymin
        yLabelsWidth = max(labelsFontM.width(label['text']) for label in ds.ylabels)
        labelsHeight = labelsFontM.height()
        graphWidth = viewWidth - yLabelsWidth - (self.PADDING * 2)
        graphHeight = viewHeight - labelsHeight - (self.PADDING * 2)
        xFactor = graphWidth / dataWidth
        yFactor = graphHeight / dataHeight
        graphLeft = round(ds.xmin * xFactor)
        graphRight = round(ds.xmax * xFactor)
        graphBottom = round(ds.ymin * yFactor)
        if graphBottom < 0:
            # We have a graph with negative values and we need some extra space to draw the lowest values
            graphBottom -= 2 * self.LINE_WIDTH
        graphTop = round(ds.ymax * yFactor)

        # High level save, restored just before drawing the title
        painter.save()
        
        shiftX = yLabelsWidth + self.PADDING - graphLeft
        shiftY = self.PADDING + graphTop
        painter.translate(shiftX, shiftY)
        painter.scale(1, -1)
        painter.setPen(axisPen)
        
        painter.save()
        self.current_painter = painter
        ds.draw(xFactor, yFactor)
        del self.current_painter
        painter.restore()
        
        # X/Y axis
        painter.drawLine(graphLeft, graphBottom, graphRight, graphBottom)
        painter.drawLine(graphLeft, graphBottom, graphLeft, graphTop)
        if graphBottom < 0:
            painter.drawLine(graphLeft, 0, graphRight, 0)
        
        # X tickmarks
        tickBottomY = graphBottom - self.TICKMARKS_LENGTH
        for tickPos in ds.xtickmarks:
            tickX = tickPos * xFactor
            painter.drawLine(tickX, graphBottom, tickX, tickBottomY)
        
        # Y tickmarks
        tickLeftX = graphLeft - self.TICKMARKS_LENGTH
        for tickPos in ds.ytickmarks:
            tickY = tickPos * yFactor
            painter.drawLine(graphLeft, tickY, tickLeftX, tickY)
        
        # X Labels
        # We have to invert the Y scale again or else the text is drawn upside down
        labelY = graphBottom - labelsFontM.ascent() - self.XLABELS_PADDING
        painter.setFont(labelsFont)
        painter.save()
        painter.translate(0, labelY)
        painter.scale(1, -1)
        for label in ds.xlabels:
            labelText = label['text']
            labelWidth = labelsFontM.width(labelText)
            labelX = (label['pos'] * xFactor) - (labelWidth / 2)
            painter.drawText(QPoint(labelX, 0), labelText)
        painter.restore()
        
        # Y Labels
        painter.setFont(labelsFont)
        for label in ds.ylabels:
            labelText = label['text']
            labelWidth = labelsFontM.width(labelText)
            labelX = graphLeft - self.YLABELS_PADDING - labelWidth
            labelY = (label['pos'] * yFactor) - (labelsFontM.ascent() / 2)
            painter.save()
            painter.translate(0, labelY)
            painter.scale(1, -1)
            painter.drawText(QPoint(labelX, 0), labelText)
            painter.restore()
        
        # High level restore
        painter.restore()
                
        # title
        painter.save()
        titleFont = QFont(painter.font())
        titleFont.setPointSize(self.TITLE_FONT_SIZE)
        titleFont.setBold(True)
        painter.setFont(titleFont)
        title = "{0} ({1})".format(self.dataSource.title, self.dataSource.currency.code)
        titleWidth = painter.fontMetrics().width(title)
        titleHeight = painter.fontMetrics().height()
        titleX = middleX - (titleWidth // 2)
        titleY = self.PADDING
        painter.drawText(QPoint(titleX, titleY), title)
        painter.restore()
    
