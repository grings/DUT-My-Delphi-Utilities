UNIT dutFixLineEndings;

{=============================================================================================================
   2026.09.06
   www.GabrielMoraru.com
   Github.com/GabrielOnDelphi/Delphi-LightSaber/blob/main/System/Copyright.txt
--------------------------------------------------------------------------------------------------------------
   AGENT: Fix Line Endings (LF/CR)  
--------------------------------------------------------------------------------------------------------------
   This agent replaces solitary CR or LF characters with "normal" Windows CRLF,
   and optionally replaces non-breaking space (#160) with a standard space.
=============================================================================================================}

INTERFACE

USES
  System.SysUtils, System.Classes, System.StrUtils,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.Mask, Vcl.ExtCtrls,
  LightCore.SearchResult, dutBase, LightVcl.Visual.Memo, LightVcl.Visual.AppDataForm;
	
TYPE
  TfrmSettings = class(TLightForm)
    Container: TPanel;
    chkNbsp: TCheckBox;
  private
  public
    procedure FormPostInitialize; override;
    procedure FormPreRelease; override;
  end;


TYPE
  TAgent_FixLineEndings = class(TBaseAgent)
  private   
    FormSettings: TfrmSettings;
    FReplaceNbsp: Boolean;    // Corresponds to chkNbsp
  public
    constructor Create(BackupFile: Boolean); override;
    destructor Destroy; override;

    procedure Execute(const FileName: string); override;
    class function Description: string; override;
    class function CanReplace: Boolean; override;
    class function AgentName: string; override;
    procedure DockSettingsForm(HostPanel: TPanel); override;
  end;



IMPLEMENTATION {$R *.dfm}
USES
   LightCore.IO, LightCore.TextFile, LightVcl.Common.IO, LightCore.AppData, LightCore, LightCore.Time, LightCore.Types, LightVcl.Common.SystemTime, LightVcl.Visual.INIFile,
   LightVcl.Common.Dialogs,
   LightVcl.Visual.AppData,
   LightCore.INIFileQuick,
   LightVcl.Common.Clipboard;  
   	 
	 
class function TAgent_FixLineEndings.Description: string;
begin
  Result := 'Replaces solitary CR/LF with CRLF, and optionally fixes #160 (non-breaking space).';
end;

   
constructor TAgent_FixLineEndings.Create(BackupFile: Boolean);
begin
  inherited Create(BackupFile);
  { Owned by the agent (NIL owner), NOT by AppData/Application. If Application owned it, shutdown could free the
    form before this agent's destructor runs, and the destructor's FormSettings.Container.Parent would touch freed memory.
    An 'if Assigned' guard would not help - the reference dangles, it does not become NIL. }
  FormSettings:= TfrmSettings.Create(NIL, asFull);   // Freed by this agent's destructor
  FormSettings.LoadForm;
end;


procedure TAgent_FixLineEndings.Execute(const FileName: string);
var
  sOutput: string;
begin
  // Setup - The base agent creates the TSearchResult object and loads the file
  inherited Execute(FileName);

  FReplaceNbsp:= FormSettings.chkNbsp.Checked;

  // Body
  if TextBody.Count = 0 then Exit;
  sOutput:= TextBody.Text;

  // Skip Binary DFM check
  if  (IsDfm(FileName))
  AND (sOutput.Length > 0)
  AND (sOutput[1] = char($FF)) then
  begin
    SearchResults.Last.AddNewPos('Binary DFM skipped!');
    Exit;
  end;

  // Transformation
  { AdjustLineBreaks does the whole job in one pass: a solitary LF becomes CRLF, a solitary CR becomes CRLF,
    an existing CRLF pair is left alone. It counts first, then fills one pre-sized string.
    Verified in c:\Delphi\Delphi 13\source\rtl\sys\System.SysUtils.pas, line 8399.
    It replaces the ReplaceLonellyLF + ReplaceLonellyCR pair, which built the result one character at a time
    and reallocated the string on every character. Same output, quadratic cost.
    FixEnters.Engine.pas (the standalone FixEnters.exe) does the same thing the same way - keep them in step. }
  sOutput := System.SysUtils.AdjustLineBreaks(sOutput, tlbsCRLF);
  if FReplaceNbsp
  then sOutput := ReplaceNbsp(sOutput, ' ');     // Replace character #160 (A0) with space

  // Save
  if sOutput <> TextBody.Text then
  begin
    // The file needs fixing. We report the issue.
    // NOTE: This agent reports the file as a whole, not specific lines/columns.
    // We use the simpler AddNewPos overload to mark the file as 'found'.
    if Replace
    then SearchResults.Last.AddNewPos('Line endings and/or #160 fixed.')
    else SearchResults.Last.AddNewPos('Bad line endings and/or #160 found.');

    // Prepare for saving if replacement is enabled
    if Replace
    then TextBody.Text:= sOutput;
  end;

  // Finalize handles internal counters and cleanup.
  Finalize;
end;


class function TAgent_FixLineEndings.CanReplace: Boolean;
begin
  // This agent modifies the file, so it allows replacement.
  Result := TRUE;
end;


procedure TAgent_FixLineEndings.DockSettingsForm(HostPanel: TPanel);
begin
  FormSettings.Container.Parent:= HostPanel;
end;


destructor TAgent_FixLineEndings.Destroy;
begin
  FormSettings.Container.Parent:= FormSettings; // Bring the container back
  FreeAndNil(FormSettings);
  inherited;
end;


class function TAgent_FixLineEndings.AgentName: string;
begin
  Result := 'Fix Line Endings';
end;




{ FORM }

procedure TfrmSettings.FormPostInitialize;
begin
  inherited;
end;


procedure TfrmSettings.FormPreRelease;
begin
  inherited;
end;


end.