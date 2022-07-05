
////////////////////////////////////////////////////////////////////////////////
// FORM ITEMS EVENT HANDLERS

// OK button handler
//
&AtClient
Procedure OK(Command)

	NotifyChoice(New Structure("Source, Result, Expression", "EditExpressionForm", True,
		TextDocumentField.GetText()));

EndProcedure
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	ExpressionTextLabel =
	NStr("ru = 'В тексте выражения можно использовать следующие предопределенные параметры:
	|   Результат      - результат вычисления (на входе - значение по умолчанию)
	|   ТекстЯчейки    - текст текущей ячейки
	|   ТекстыЯчеек    - массив текстов ячеек строки
	|   ТекущиеДанные  - структура загруженных значений
	|   ОписаниеОшибки - описание ошибки, выводимое в примечание ячейки и в окно сообщений
	|Встроенные функции, функции общих модулей.';
	|en = 'The following predefined parameters are available in the expression text:
	|   Result         - An evaluation result. Default value on start of the procedure.
	|   CellText       - A current cell text.
	|   CellsTexts     - An array of row cells texts.
	|   CurrentData    - A structure with an imported values.
	|	ErrorDescription - A description of an error which can be put out to cell tootlip and to message window.
	|Embedded functions, common module functions.'");
EndProcedure