&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	ObjectType = Parameters.ObjectType;
	ProcessTabularParts = Parameters.ProcessTabularParts;
	ListOfSelected = Parameters.ListOfSelected;

	Tree = FormDataToValue(TreeTable, Type("ValueTree"));

	Tree.Rows.Clear();

	MetadataOfObjects = Metadata[?(ObjectType = 1, "Documents", "Catalogs")];
//	ИмяТипаОбъекта = ?(ObjectType = 1,"Document","Catalog");
	If ProcessTabularParts Then
		If ObjectType = 1 Then
			Title = Nstr("ru = 'Фильтр по табличным частям документов ';en = 'Filter by tabular parts of documents'");
		Else
			Title = Nstr("ru = 'Фильтр по табличным частям справочников ';en = 'Filter by tabular parts of catalogs'");
		EndIf;
		
	Else
		If ObjectType = 1 Then
			Title = Nstr("ru = 'Фильтр по документам';en = 'Filter by documents'");
		Else
			Title = Nstr("ru = 'Фильтр по справочникам';en = 'Filter by catalogs'");
		EndIf;
	EndIf;
	For Each MetadataItem In MetadataOfObjects Do

		If ProcessTabularParts And MetadataItem.TabularSections.Count() = 0 Then

			Continue;

		EndIf;
		String                      = Tree.Rows.Add();
		MetadataName              = MetadataItem.Name;
		String.TableName           = MetadataName;
		String.RepresentationTable = MetadataItem.Presentation();

		If Not ProcessTabularParts Then

			If Not ListOfSelected.FindByValue(MetadataName) = Undefined Then

				String.Check = True;

			EndIf;

		Else
			CheckParent = Undefined;
			For Each TabularSection In MetadataItem.TabularSections Do

				RowTabularSection            			= String.Rows.Add();
				TableName                    			= TabularSection.Name;
				RowTabularSection.TableName           	= MetadataName + "." + TableName;
				RowTabularSection.RepresentationTable 	= TabularSection.Presentation();

				If Not ListOfSelected.FindByValue(MetadataName + "." + TableName) = Undefined Then

					RowTabularSection.Check = True;

				EndIf;

				If CheckParent = Undefined Then
					CheckParent = RowTabularSection.Check;
				ElsIf Not CheckParent = 2 And CheckParent <> RowTabularSection.Check Then
					CheckParent = 2;
				EndIf;

			EndDo;
			String.Check = CheckParent;
		EndIf;
	EndDo;

	ValueToFormData(Tree, TreeTable);
EndProcedure

&AtClient
Procedure TreeTableCheckOnChange(Item)
	CurrentData = Items.TreeTable.CurrentData;

	If CurrentData.Check = 2 Then
		CurrentData.Check = 0;
	EndIf;

	If CurrentData.GetParent() <> Undefined Then
		CheckParent = CurrentData.Check;
		For Each String In CurrentData.GetParent().GetItems() Do
			If String.Check <> CheckParent Then
				CheckParent = 2;
				Break;
			EndIf;
		EndDo;
		CurrentData.GetParent().Check = CheckParent;
	Else
		For Each String In CurrentData.GetItems() Do
			String.Check = CurrentData.Check;
		EndDo;
	EndIf;
EndProcedure

&AtClient
Procedure Choose(Command)
//	ИмяТипаОбъекта = ?(ObjectType = 1,"Document","Catalog");
	ListOfSelected.Clear();
	For Each String In TreeTable.GetItems() Do
		If Not ProcessTabularParts Then

			If String.Check Then
				ListOfSelected.Add(String.TableName, String.RepresentationTable);
			EndIf
			;

		Else

			For Each RowTable In String.GetItems() Do

				If RowTable.Check Then
					ListOfSelected.Add(RowTable.TableName, String.RepresentationTable + " [ ТЧ : "
						+ RowTable.RepresentationTable + " ] ");
				EndIf
				;

			EndDo;
		EndIf;

	EndDo;
	Close(ListOfSelected);
EndProcedure

&AtClient
Procedure SetChecksOnAllLines(NewCheck)
	For Each String In TreeTable.GetItems() Do
		String.Check = NewCheck;
		If ProcessTabularParts Then
			For Each RowTable In String.GetItems() Do
				RowTable.Check = NewCheck;
			EndDo;
		EndIf;

	EndDo;

EndProcedure

&AtClient
Procedure SetMarks(Command)
	SetChecksOnAllLines(1);
EndProcedure

&AtClient
Procedure RemoveMarks(Command)
	SetChecksOnAllLines(0);
EndProcedure