Function GetDataProcessorTemplate(Name) Export
	Return GetTemplate(Name);
EndFunction

/////////////////////////////////////////////////////////////////////////////
// INTERFACE

// Data processor register interface.
// Called on import data processor to the ExternalDataProcessor catalog.
//
// Return value:
// 	- Structure:
// 		- Kind - String - available values:	"AdditionalDataProcessor"
//											"AdditionalReport"
//											"ObjectFilling"
//											"Report"
//											"PrintForm"
//											"RelatedObjectsCreation".
//
// 		- Purpose - metadata types array with mask:
//					   <MetadataObjectClassName>.[ * | <MetadataObjectName>]
//					   For example, "Document.InvoiceOrder" or "Catalog.*".
//					   This parameter in used only for assignable data processors. 
//
// 		- Description - String - data processor description 
// 						to be written to catalog item description as default - 
// 						short name for identifying data processor.
//
// 		- Version - String - data processor version. Conforms to <senior number>.<junior number> format.
//					It is used when data processor is imported to the infobase.
//					
// 		- SafeMode – Boolean – if True, Data processor will be started in safe mode.
//					 See Help for further information.
//
// 		- Information - String - data processor details.
//
// 		- Commands - ValueTable - command interface provided by data processor.
// 					 Every table row describes a different command.
// 					 
//				columns: 
//				 - Presentation - String - a user presentation of the command.
//				 - ID - String - command ID. For external print forms (when Kind = "PrintForm"):
//                 		ID can contain comma-separated names of one or more print commands.
//				 - Usage - String - data processor usage options:
//						"FormOpening" - open data processor form.
//						"ClientMethodCall" - calling of data processor form client export method.
//						"ServerMethodCall" - calling of data processor object module server export method.
//				 - ShowNotification – boolean – if True, show "Executing command..." notification upon command execution.
//				  		It is used for all command types except for commands for opening a form (Usage = "FormOpening".)
//				 - Modifier – String - an additional command classification.
//				 		For external print forms (when Kind = "PrintForm"):
//                 		"MXLPrinting" - for print forms generated on the basis of spreadsheet templates.
//
Function ExternalDataProcessorInfo() Export

	RegistrationParameters = New Structure;

	RegistrationParameters.Insert("Kind", "AdditionalDataProcessor");
	RegistrationParameters.Insert("Purpose", Undefined);
	RegistrationParameters.Insert("Description", NStr("ru = 'Загрузка данных из табличного документа'; en = 'Import data from spreadsheet document'"));
	RegistrationParameters.Insert("Version", "1.4");
	RegistrationParameters.Insert("SafeMode", False);
	RegistrationParameters.Insert("Information", NStr(
		"ru = 'Обработка используется для загрузки данных в справочники, табличные части документов и справочников, а также в регистры сведений из табличного документа в формате Excel, MXL, DBF, txt.';
		|en = 'The data processor is used to import data into catalogs, tabular sections of documents and catalogs, as well as into information registers from a spreadsheet document in Excel, MXL, DBF, txt format.'"));

	CommandTable = GetCommandTable();

	AddCommand(CommandTable, NStr("ru = 'Загрузка из табличного документа'; en = 'Import from spreadsheet document'"),
		"Opening_ImportDataFromSpreadsheetDocument_" + StrReplace(RegistrationParameters.Version, ".", "_"),
		"FormOpening");

	RegistrationParameters.Insert("Commands", CommandTable);

	Return RegistrationParameters;

EndFunction

/////////////////////////////////////////////////////////////////////////////
// PRIVATE

Function GetCommandTable()

	Commands = New ValueTable;
	Commands.Columns.Add("Presentation", New TypeDescription("String"));
	Commands.Columns.Add("ID", New TypeDescription("String"));
	Commands.Columns.Add("Usage", New TypeDescription("String"));
	Commands.Columns.Add("ShowNotification", New TypeDescription("Boolean"));
	Commands.Columns.Add("Modifier", New TypeDescription("String"));

	Return Commands;

EndFunction

Procedure AddCommand(CommandTable, Presentation, ID, Usage, ShowNotification = False,
	Modifier = "")

	NewCommand = CommandTable.Add();
	NewCommand.Presentation = Presentation;
	NewCommand.ID = ID;
	NewCommand.Usage = Usage;
	NewCommand.ShowNotification = ShowNotification;
	NewCommand.Modifier = Modifier;

EndProcedure

// Interface for starting data processor
//
// Parameters
// 	- CommandID - String - Internal ID of calling command
//
Procedure ExecuteCommand(CommandID) Export
EndProcedure