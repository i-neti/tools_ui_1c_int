#Region Variables

&AtClient
Var UT_CodeEditorClientData Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("Title") Then
		Title  = Parameters.Title;
	EndIf;

	ExpressionText = Parameters.Text;
	
	ЗаполнитьДоступныеПоляСКД();
	
	UT_CodeEditorServer.FormOnCreateAtServer(ThisObject);

	UT_CodeEditorServer.CreateCodeEditorItems(ThisObject,
													   "Expression",
													   Items.ПолеРедактированияВыражения,
													   ,
													   "dcs_query");
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	UT_CodeEditorClient.ФормаПриОткрытии(ThisObject);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers


&AtClient
Procedure ПоляСКДВыбор(Item, SelectedRow, Field, StandardProcessing)
	StandardProcessing = False;
	
	RowData = ПоляСКД.FindByID(SelectedRow);
	UT_CodeEditorClient.ВставитьТекстПоПозицииКурсора(ThisObject, "Expression", RowData.DataPath);
EndProcedure

#EndRegion


#Region CommandFormEventHandlers

&AtClient
Procedure Apply(Command)
	Close(ТекущийТекстВыражения());
EndProcedure

#EndRegion

#Region Private

#Region РедакторКода

&AtClient
Procedure УстановитьТекстВыражения(НовыйТекст, УстанавливатьОригинальныйТекст = False, НовыйОригинальныйТекст = "")
	UT_CodeEditorClient.УстановитьТекстРедактора(ThisObject, "Expression", НовыйТекст);

	If УстанавливатьОригинальныйТекст Then
		UT_CodeEditorClient.УстановитьОригинальныйТекстРедактора(ThisObject, "Expression", НовыйОригинальныйТекст);
	EndIf;
EndProcedure

&AtClient
Function ТекущийТекстВыражения()
	Return UT_CodeEditorClient.ТекстКодаРедактора(ThisObject, "Expression");
EndFunction

//@skip-warning
&AtClient
Procedure Подключаемый_ПолеРедактораДокументСформирован(Item)
	UT_CodeEditorClient.ПолеРедактораHTMLДокументСформирован(ThisObject, Item);
EndProcedure

//@skip-warning
&AtClient
Procedure Подключаемый_ПолеРедактораПриНажатии(Item, ДанныеСобытия, StandardProcessing)
	UT_CodeEditorClient.ПолеРедактораHTMLПриНажатии(ThisObject, Item, ДанныеСобытия, StandardProcessing);
EndProcedure

//@skip-warning
&AtClient
Procedure Подключаемый_РедакторКодаОтложеннаяИнициализацияРедакторов()
	UT_CodeEditorClient.РедакторКодаОтложеннаяИнициализацияРедакторов(ThisObject);
EndProcedure

&AtClient
Procedure Подключаемый_РедакторКодаЗавершениеИнициализации() Export
	УстановитьТекстВыражения(ExpressionText, True, ExpressionText);
	УИ_ДобавитьКонтекстПолей();
EndProcedure

&AtClient
Procedure Подключаемый_РедакторКодаОтложеннаяОбработкаСобытийРедактора() Export
	UT_CodeEditorClient.ОтложеннаяОбработкаСобытийРедактора(ThisObject);
EndProcedure

#EndRegion

&AtServer
Procedure ЗаполнитьДоступныеПоляСКД()
	
	ВидыПолей = Parameters.ВидыПолейНаборовДанных;
	КартинкаРеквизит=PictureLib.Attribute;
	КартинкаПроизвольноеВыражение=PictureLib.CustomExpression;
	КартинкаПапка = PictureLib.Folder;
	
	СоответствиеИдентификаторовСтрок = New Map;

	For Each ТекПоле ИЗ Parameters.Fields Do
		If ТекПоле.Type <> ВидыПолей.Field Then
			Continue;
		EndIf;
		
		МассивПути = StrSplit(ТекПоле.DataPath, ".", False);
		
		ТекПуть = "";
		CurrentParent = ПоляСКД;
		
		For ИндексПути=0  To МассивПути.Count()-1 Do
			ЭлементПути = МассивПути[ИндексПути];
			
			ТекПуть = ТекПуть + ?(ValueIsFilled(ТекПуть),".","") + ЭлементПути;
			
			If ТекПуть = ТекПоле.DataPath Then
				НовоеПоле = CurrentParent.GetItems().Add();
				НовоеПоле.Field = ЭлементПути;
				НовоеПоле.DataPath = ТекПуть;
				НовоеПоле.ValueType = ТекПоле.ValueType;
				If НовоеПоле.ValueType = New TypeDescription Then
					НовоеПоле.ValueType = ТекПоле.ТипЗначенияЗапроса;
				EndIf;
				If ТекПоле.ВычисляемоеПоле Then
					НовоеПоле.Picture = КартинкаПроизвольноеВыражение;	
				Else
					НовоеПоле.Picture = КартинкаРеквизит;
				EndIf;
				
				Continue;
			EndIf;
			
			ИдентификаторСтроки = СоответствиеИдентификаторовСтрок[Lower(ТекПуть)];
			If ИдентификаторСтроки = Undefined Then
				НовоеПоле = CurrentParent.GetItems().Add();
				НовоеПоле.Field = ЭлементПути;
				НовоеПоле.DataPath = ТекПуть;
				НовоеПоле.ValueType = New TypeDescription("Number");
				НовоеПоле.Picture = КартинкаПапка;

				ИдентификаторСтроки = НовоеПоле.GetID();
				СоответствиеИдентификаторовСтрок.Insert(Lower(ТекПуть), ИдентификаторСтроки);
				
				CurrentParent = НовоеПоле;
			Else
				CurrentParent = ПоляСКД.FindByID(ИдентификаторСтроки);
			EndIf;
		EndDo;
	EndDo;
	
	ПапкаСистемныеПоля = ПоляСКД.GetItems().Add();
	ПапкаСистемныеПоля.DataPath = "СистемныеПоля";
	ПапкаСистемныеПоля.Field = "СистемныеПоля";
	ПапкаСистемныеПоля.Picture = КартинкаПапка;
	
	НовоеПоле = ПапкаСистемныеПоля.GetItems().Add();
	НовоеПоле.Field = "НомерПоПорядку";
	НовоеПоле.DataPath = ПапкаСистемныеПоля.DataPath+"."+НовоеПоле.Field;
	НовоеПоле.ValueType = New TypeDescription("Number");
	НовоеПоле.Picture = КартинкаРеквизит;
	
	НовоеПоле = ПапкаСистемныеПоля.GetItems().Add();
	НовоеПоле.Field = "НомерПоПорядкуВГруппировке";
	НовоеПоле.DataPath = ПапкаСистемныеПоля.DataPath+"."+НовоеПоле.Field;
	НовоеПоле.ValueType = New TypeDescription("Number");
	НовоеПоле.Picture = КартинкаРеквизит;
	
	НовоеПоле = ПапкаСистемныеПоля.GetItems().Add();
	НовоеПоле.Field = "Level";
	НовоеПоле.DataPath = ПапкаСистемныеПоля.DataPath+"."+НовоеПоле.Field;
	НовоеПоле.ValueType = New TypeDescription("Number");
	НовоеПоле.Picture = КартинкаРеквизит;
	
	НовоеПоле = ПапкаСистемныеПоля.GetItems().Add();
	НовоеПоле.Field = "УровеньВГруппировке";
	НовоеПоле.DataPath = ПапкаСистемныеПоля.DataPath+"."+НовоеПоле.Field;
	НовоеПоле.ValueType = New TypeDescription("Number");
	НовоеПоле.Picture = КартинкаРеквизит;
	
EndProcedure

&AtClient
Procedure ДобавитьКонтекстГруппыПолей(СтруктураДополнительногоКонтекста, СтрокаПолейСКД, ПустоеОписаниеТипов)
	For Each ДоступнаяПеременная In СтрокаПолейСКД.GetItems() Do
		КоллекцияПодчиненных = ДоступнаяПеременная.GetItems();
		If КоллекцияПодчиненных.Count() = 0 Then
			Types = ДоступнаяПеременная.ValueType.Types();
			If Types.Count() = 0 Then
				СтруктураПеременной = "";
			Else
				СтруктураПеременной = Types[0];
			EndIf;
		Else
			СтруктураПеременной = New Structure;
			If ДоступнаяПеременная.ValueType = ПустоеОписаниеТипов Then
				СтруктураПеременной.Insert("Type", "");
			Else
				СтруктураПеременной.Insert("Type", ДоступнаяПеременная.ValueType);
			EndIf;
			ПодчиненныеСвойства = New Structure;
			
			ДобавитьКонтекстГруппыПолей(ПодчиненныеСвойства, ДоступнаяПеременная, ПустоеОписаниеТипов);
			СтруктураПеременной.Insert("ПодчиненныеСвойства", ПодчиненныеСвойства);
			
		EndIf;
		
		СтруктураДополнительногоКонтекста.Insert(ДоступнаяПеременная.Field, СтруктураПеременной);
	EndDo;
	
EndProcedure

&AtClient
Procedure УИ_ДобавитьКонтекстПолей()
	СтруктураДополнительногоКонтекста = New Structure;

	ПустоеОписаниеТипов = New TypeDescription;
	
	ДобавитьКонтекстГруппыПолей(СтруктураДополнительногоКонтекста, ПоляСКД, ПустоеОписаниеТипов);
	
	UT_CodeEditorClient.ДобавитьКонтекстРедактораКода(ThisObject, "Expression", СтруктураДополнительногоКонтекста);

EndProcedure


#EndRegion