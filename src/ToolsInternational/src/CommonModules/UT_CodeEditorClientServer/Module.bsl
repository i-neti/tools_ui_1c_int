#Region Public

Function CodeEditorItemsPrefix() Export
	Return "CodeEditor1C";
EndFunction

Function AttributeNameCodeEditor(EditorID) Export
	Return CodeEditorItemsPrefix()+"_"+EditorID;
EndFunction

Function AttributeNameCodeEditorTypeOfEditor() Export
	Return CodeEditorItemsPrefix()+"_EditorType";
EndFunction

Function AttributeNameCodeEditorLibraryURL() Export
	Return CodeEditorItemsPrefix()+"_LibraryUrlInTempStorage";
EndFunction

Function AttributeNameCodeEditorFormCodeEditors() Export
	Return CodeEditorItemsPrefix()+"_FormEditorsList";
EndFunction
// Attribute Name Code Editor Initial Initialization Passed.
// 
// Return :
// String 
Function AttributeNameCodeEditorInitialInitializationPassed() Export
	Return CodeEditorItemsPrefix()+"_InitialInitializationPassed";
EndFunction

Function AttributeNameCodeEditorFormEditors(EditorID) Export
	Return CodeEditorItemsPrefix()+"_FormEditors";
EndFunction

Function CodeEditorVariants() Export
	Variants = New Structure;
	Variants.Insert("Text", "Text");
	Variants.Insert("Ace", "Ace");
	Variants.Insert("Monaco", "Monaco");

	Return Variants;
EndFunction

Function EditorVariantByDefault() Export
	Return CodeEditorVariants().Monaco;
EndFunction

Function CodeEditorUsesHTMLField(EditorType) Export
	Variants=CodeEditorVariants();
	Return EditorType = Variants.Ace
		Or EditorType = Variants.Monaco;
EndFunction

// Initial Initialization of Code editors passed
// 
// Parameters:
//  Form - ClientApplicationForm
// 
// Return:
//  Boolean
Function CodeEditorsInitialInitializationPassed(Form) Export
	Return Form[AttributeNameCodeEditorInitialInitializationPassed()];
EndFunction 

// Set Flag Code Editors Initial Initialization Passed.
// 
// Parameters:
//  Form - ClientApplicationForm
//  InitializationPassed - Булево
Procedure SetFlagCodeEditorsInitialInitializationPassed(Form, InitializationPassed) Export
	Form[AttributeNameCodeEditorInitialInitializationPassed()] = InitializationPassed;
EndProcedure

Function EditorIDByFormItem(Form, Item) Export
	FormEditors = Form[UT_CodeEditorClientServer.AttributeNameCodeEditorFormCodeEditors()];

	For Each KeyValue In FormEditors Do
		If KeyValue.Value.EditorField = Item.Name Then
			Return KeyValue.Key;
		EndIf;
	EndDo;

	Return Undefined;
EndFunction

Function ExecuteAlgorithm(__AlgorithmText__, __Context__) Export
	Successfully = True;
	ErrorDescription = "";
	
	AlgorithmExecutedText = AlgorithmCodeSupplementedWithContext(__AlgorithmText__, __Context__);

	ExecutionStart = CurrentUniversalDateInMilliseconds();
	Try
		Execute (AlgorithmExecutedText);
	Except
		Successfully = False;
		ErrorDescription = ErrorDescription();
		Message(ErrorDescription);
	EndTry;
	ExecutionFinish = CurrentUniversalDateInMilliseconds();

	ExecutionResult = New Structure;
	ExecutionResult.Insert("Successfully", Successfully);
	ExecutionResult.Insert("ExecutionTime", ExecutionFinish - ExecutionStart);
	ExecutionResult.Insert("ErrorDescription", ErrorDescription);

	Return ExecutionResult;
EndFunction

Function FormCodeEditorType(Form) Export
	Return Form[UT_CodeEditorClientServer.AttributeNameCodeEditorTypeOfEditor()];
EndFunction
// New Text Cache Of Editor.
// 
// Return:
//  Structure - New Text Cache Of Editor:
// * Text - String -
// * OriginalText - String -
Function NewTextCacheOfEditor() Export
	Structure = New Structure;
	Structure.Insert("Text", "");
	Structure.Insert("OriginalText", "");
	
	Return Structure;
EndFunction

#EndRegion

#Region Internal

Function MonacoEditorSyntaxLanguageVariants() Export
	SyntaxLanguages = New Structure;
	SyntaxLanguages.Insert("Auto", "Auto");
	SyntaxLanguages.Insert("Russian", "Russian");
	SyntaxLanguages.Insert("English", "English");
	
	Return SyntaxLanguages;
EndFunction

Function MonacoEditorThemeVariants() Export
	Variants = New Structure;
	
	Variants.Insert("Light", "Light");
	Variants.Insert("Dark", "Dark");
	
	Return Variants;
EndFunction

Function MonacoEditorThemeVariantByDefault() Export
	EditorThemes = MonacoEditorThemeVariants();
	
	Return EditorThemes.Light;
EndFunction
Function MonacoEditorSyntaxLanguageByDefault() Export
	Variants = MonacoEditorSyntaxLanguageVariants();
	
	Return Variants.Auto;
EndFunction

Function  MonacoEditorParametersByDefault() Export
	EditorSettings = New Structure;
	EditorSettings.Insert("LinesHeight", 0);
	EditorSettings.Insert("Theme", MonacoEditorThemeVariantByDefault());
	EditorSettings.Insert("ScriptVariant", MonacoEditorSyntaxLanguageByDefault());
	EditorSettings.Insert("UseScriptMap", False);
	EditorSettings.Insert("HideLineNumbers", False);
	EditorSettings.Insert("DisplaySpacesAndTabs", False);
	EditorSettings.Insert("SourceFilesDirectories", New Array);
	EditorSettings.Insert("CodeTemplatesFiles", New Array);
	EditorSettings.Insert("UseStandartCodeTemplates", True);
	
	Return EditorSettings;
EndFunction

Function CodeEditorCurrentSettingsByDefault() Export
	EditorSettings = New Structure;
	EditorSettings.Insert("Variant",  EditorVariantByDefault());
	EditorSettings.Insert("FontSize", 0);
	EditorSettings.Insert("Monaco", MonacoEditorParametersByDefault());
	
	Return EditorSettings;
EndFunction

Function NewDescriptionOfConfigurationSourceFilesDirectory() Export
	Description = New Structure;
	Description.Insert("Directory", "");
	Description.Insert("Source", "");
	
	Return Description;
EndFunction

#EndRegion

#Region Private

Function AlgorithmCodeSupplementedWithContext(AlgorithmText, Context)
	PreparedCode="";

	For Each KeyValue In Context Do
		PreparedCode = PreparedCode +"
		|"+KeyValue.Key+"=__Context__."+KeyValue.Key+";";
	EndDo;

	PreparedCode=PreparedCode + Chars.LF + AlgorithmText;

	Return PreparedCode;
EndFunction

#EndRegion