////////////////////////////////////////////////////////////////////////////////
// PRIVATE

// Sets a label with a text of an expression.
//
&AtClient
Procedure SetExpressionTextLabel()
	If ImportMode = 1 Then

		If Items.BarGroup.CurrentPage.Name = "AfterAddRowGroup" Then

			ExpressionTextLabel =
			NStr("ru = 'В тексте выражения можно использовать следующие предопределенные параметры:
			|   Объект         - Записываемый объект
			|   ТекущиеДанные  - Содержит данные загружаемой строки табличной части.
			|   ТекстыЯчеек    - массив текстов ячеек строки
			|Встроенные функции, функции общих модулей.';
			|en = 'The following predefined parameters are available in the expression text:
			|   Object         - Written object.
			|   CurrentData    - Imported table row data.
			|   CellsTexts     - An array of row cells texts.
			|Embedded functions, common module functions.'");
		Else

			ExpressionTextLabel =
			NStr("ru = 'В тексте выражения можно использовать следующие предопределенные параметры:
			|   Объект         - Записываемый объект
			|   Отказ          - Признак отказа от записи объекта
			|Встроенные функции, функции общих модулей.';
			|en = 'The following predefined parameters are available in the expression text:
			|   Object         - Written object.
			|	Cancel		   - Write cancel flag.
			|Embedded functions, common module functions.'");

		EndIf;

	ElsIf ImportMode = 0 Then

		ExpressionTextLabel =
		NStr("ru = 'В тексте выражения можно использовать следующие предопределенные параметры:
		|   Объект         - Записываемый объект
		|   Отказ          - Признак отказа от записи объекта
		|   ТекстыЯчеек    - массив текстов ячеек строки
		|Встроенные функции, функции общих модулей.';
		|en = 'The following predefined parameters are available in the expression text:
		|   Object         - Written object.
		|   Cancel		   - Write cancel flag.
		|   CellsTexts     - An array of row cells texts.
		|Embedded functions, common module functions.'");

	ElsIf ImportMode = 2 Then
		ExpressionTextLabel =
		NStr("ru = 'В тексте выражения можно использовать следующие предопределенные параметры:
		|   Объект         - Менеджер записи регистра сведений
		|   Отказ          - Признак отказа от записи объекта
		|   ТекстыЯчеек    - массив текстов ячеек строки
		|Встроенные функции, функции общих модулей.';
		|en = 'The following predefined parameters are available in the expression text:
		|   Object         - Information register record manager.
		|   Cancel		   - Write cancel flag.
		|   CellsTexts     - An array of row cells texts.
		|Embedded functions, common module functions.;");
	EndIf;

EndProcedure // ()

////////////////////////////////////////////////////////////////////////////////
// FORM EVENT HANDLERS

&AtClient
Procedure OnOpen(Cancel)

	If ImportMode = 2 Then
		Items.BarGroup.Pages.BeforeWriteObjectGroup.Title = NStr("ru = 'Перед записью'; en = 'Before write'");
		Items.BarGroup.Pages.OnWriteObjectGroup.Title =    NStr("ru = 'При записи'; en = 'On write'");
	EndIf;

	Items.AfterAddRowGroup.Visible = ImportMode = 1;
	SetExpressionTextLabel();

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// FORM ITEMS EVENT HANDLERS

// OK button handler
//
&AtClient
Procedure OK(Command)
	NotifyChoice(
		New Structure("Source, Result, BeforeWriteObject, OnWriteObject, AfterAddRow",
		"EditEventsForm", True, BeforeWriteObject.GetText(), OnWriteObject.GetText(),
		AfterAddRow.GetText()));
EndProcedure

// Page change handler
//
&AtClient
Procedure BarOnCurrentPageChange(Item, CurrentPage)
	SetExpressionTextLabel();
EndProcedure