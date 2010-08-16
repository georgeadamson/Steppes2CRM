
Const wdPageBreak = 7

Dim word
Dim doc

' Create a Word object
Set word = CreateObject("Word.Application")

word.Visible = True

Set doc = word.Documents.Add

word.Selection.InsertFile "\\selfs\Documents\2010\SV\Letter\Letter-Clear-95084-Sue Grimwood-08-06-2010_09-58.doc"
word.Selection.InsertBreak wdPageBreak
word.Selection.InsertFile "\\selfs\Documents\2010\SV\Letter\Letter-de Lance-Holmes-93286-Sally Walters-14-05-2010_12-13.doc"
word.Selection.InsertBreak wdPageBreak
word.Selection.InsertFile "\\selfs\Documents\2010\SV\Letter\Letter-Jacobs-94673-Alex Mudd-18-06-2010_15-56.doc"

doc.SaveAs "c:\temp\test.doc", 0

doc.Close
word.Quit