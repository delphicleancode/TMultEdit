unit MultEdit;

interface

uses
  System.SysUtils,
  System.Classes,
  System.UITypes,
  Vcl.Controls,
  Vcl.StdCtrls,
  Vcl.Mask,
  Vcl.Graphics,
  VCL.Dialogs;

type
  TEditType = (etNone, etEmail, etURL, etPhone, etCPF, etCNPJ, etCEP);

  TOnValidate = procedure(Sender: TObject; AValid: Boolean; AMessage: string) of object;

  TMultEdit = class(TMaskEdit)
  private
    FEditType    : TEditType;
    FColorValid  : TColor;
    FColorInvalid: TColor;
    FValid       : Boolean;
    FOnValidate  : TOnValidate;
    FVersion     : string;
    FMessage     : string;

    procedure SetMask(const Value: TEditType);
    procedure SetEditType(const Value: TEditType);

    function GetValidationSize: Integer;
  protected
    procedure KeyPress(var Key: Char); override;

    procedure CheckIsValid(const AText: string);
    function isValid(const AText: string): Boolean;

  public
    constructor Create(AOwner: TComponent); override;

    procedure ResetDefaults;

    property Valid: Boolean read FValid;

    procedure Test;
    procedure TestInput;
    procedure ShowResultValidation;
  published
    property ColorInvalid : TColor    read FColorInvalid write FColorInvalid;
    property ColorValid   : TColor    read FColorValid   write FColorValid;
    property EditType     : TEditType read FEditType     write SetEditType default etNone;
    property Version      : string    read FVersion;

    property OnValidate   : TOnValidate read FOnValidate write FOnValidate;
  end;

procedure Register;

implementation
  uses
    MultEdit.Helpers,
    System.RegularExpressions;

procedure Register;
begin
  RegisterComponents('MeusComponentes', [TMultEdit]);
end;

procedure TMultEdit.CheckIsValid(const AText: string);
begin
  if isValid(AText) then
  begin
    Self.Color := Self.ColorValid;
    FMessage   := MSG_VALID;
  end
  else
  begin
    Self.Color := Self.ColorInvalid;
    FMessage := MSG_INVALID;
  end;

  if Assigned(FOnValidate) then
    FOnValidate(Self, FValid, FMessage);
end;

constructor TMultEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FVersion := VERSION_NUMBER;

  ResetDefaults;
end;

function TMultEdit.GetValidationSize: Integer;
begin
  case Self.EditType of
    etNone : Result := Self.MaxLength;
    etEmail: Result := VALIDATION_SIZE_EMAIL;
    etURL  : Result := VALIDATION_SIZE_URL;
  else
    Result := string(Self.EditMask).CountChar(MASK_KEY_NUMBERS);
  end;
end;

function TMultEdit.isValid(const AText: string): Boolean;
begin
  case Self.EditType of
    etEmail  : Result := TRegEx.IsMatch(AText, REGEX_MAIL);
    etURL    : Result := TRegEx.IsMatch(AText, REGEX_URL);
    etPhone  : Result := TRegEx.IsMatch(AText, REGEX_PHONE);
    etCPF    : Result := CPFValid(AText);
    etCNPJ   : Result := CNPJValid(AText);
    etCEP    : Result := CEPValid(AText);
  else
    Result := True;
  end;
  FValid := Result;
end;

procedure TMultEdit.KeyPress(var Key: Char);
begin
  FValid := True;

  if Self.EditType <> etNone then
  begin
    FValid := False;

    if not (Self.EditType in [etEmail, etURL]) then
      if not CharInSet(Key, NUMBERS) then
        Key := #0;

    if Length(Trim(Self.Text) + Key) >= GetValidationSize then
      CheckIsValid(Trim(Self.Text) + Key);
  end;

  inherited;
end;

procedure TMultEdit.ResetDefaults;
begin
  FColorValid   := COLOR_VALID;
  FColorInvalid := COLOR_INVALID;
  Self.Color    := clWindow;
  FEditType     := etNone;
end;

procedure TMultEdit.SetEditType(const Value: TEditType);
begin
  FEditType := Value;
  SetMask(Value);

  if Value in [etURL, etEmail] then
    Self.CharCase := ecLowerCase
  else
    Self.CharCase := ecNormal;
end;

procedure TMultEdit.SetMask(const Value: TEditType);
begin
  case Value of
    etPhone : Self.EditMask := MASK_PHONE;
    etCPF   : Self.EditMask := MASK_CPF;
    etCNPJ  : Self.EditMask := MASK_CNPJ;
    etCEP   : Self.EditMask := MASK_CEP;
  else
    Self.EditMask := EmptyStr;
  end;
end;

procedure TMultEdit.ShowResultValidation;
begin
  if Self.Valid then
    MessageDlg(Self.FMessage, mtInformation, [mbOk], 0)
  else
    MessageDlg(Self.FMessage, mtError, [mbOk], 0);
end;

procedure TMultEdit.Test;
begin
  if FEditType = etNone then
    Exit;

  CheckIsValid(Self.Text);
  ShowResultValidation;
end;

procedure TMultEdit.TestInput;
var
  FText: string;
begin
  if FEditType = etNone then
    Exit;

  FText := InputBox('Validation', 'Text', Self.Text);
  Self.Text := FText;
  CheckIsValid(Self.Text);
  ShowResultValidation;
end;

end.
