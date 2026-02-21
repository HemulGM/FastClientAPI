unit HGM.FastClientAPI;

interface

uses
  System.Classes, System.Net.HttpClient, System.Net.URLClient, System.Net.Mime,
  System.JSON, System.SysUtils, System.Types, System.RTTI, REST.JsonReflect,
  REST.Json.Interceptors, System.Generics.Collections;

type
  TJSONInterceptorStringToString = class(TJSONInterceptor)
    constructor Create; reintroduce;
  protected
    RTTI: TRttiContext;
  end;

  TFastMultipartFormData = class(TMultipartFormData)
    constructor Create; virtual;
  end;

type
  TJSONParam = class
  private
    FJSON: TJSONObject;
    procedure SetJSON(const Value: TJSONObject);
    function GetCount: Integer;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    function Add(const Key: string; const Value: string): TJSONParam; overload; virtual;
    function Add(const Key: string; const Value: Integer): TJSONParam; overload; virtual;
    function Add(const Key: string; const Value: Extended): TJSONParam; overload; virtual;
    function Add(const Key: string; const Value: Boolean): TJSONParam; overload; virtual;
    function Add(const Key: string; const Value: TDateTime; Format: string): TJSONParam; overload; virtual;
    function Add(const Key: string; const Value: TJSONValue): TJSONParam; overload; virtual;
    function Add(const Key: string; const Value: TJSONParam): TJSONParam; overload; virtual;
    function Add(const Key: string; Value: TArray<string>): TJSONParam; overload; virtual;
    function Add(const Key: string; Value: TArray<Integer>): TJSONParam; overload; virtual;
    function Add(const Key: string; Value: TArray<Extended>): TJSONParam; overload; virtual;
    function Add(const Key: string; Value: TArray<TJSONValue>): TJSONParam; overload; virtual;
    function Add(const Key: string; Value: TArray<TJSONParam>): TJSONParam; overload; virtual;
    function GetOrCreateObject(const Name: string): TJSONObject;
    function GetOrCreate<T: TJSONValue, constructor>(const Name: string): T;
    procedure Delete(const Key: string); virtual;
    procedure Clear; virtual;
    property Count: Integer read GetCount;
    property JSON: TJSONObject read FJSON write SetJSON;
    function ToJsonString(FreeObject: Boolean = False): string; virtual;
    function ToStringPairs: TArray<TPair<string, string>>;
    function ToStream: TStringStream;
  end;

  {$IF RTLVersion < 35.0}
  TURLClientHelper = class helper for TURLClient
  public
    const
      DefaultConnectionTimeout = 60000;
      DefaultSendTimeout = 60000;
      DefaultResponseTimeout = 60000;
  end;
  {$ENDIF}

  ExceptionAPI = class(Exception);

  ExceptionAPIRequest = class(ExceptionAPI)
  private
    FCode: Int64;
    FText: string;
  public
    property Code: Int64 read FCode write FCode;
    property Text: string read FText write FText;
    constructor Create(const Text: string; Code: Int64); reintroduce;
  end;

  ExceptionAPIRequest<T: class, constructor> = class(ExceptionAPIRequest)
  private
    FError: T;
  public
    property Error: T read FError;
    constructor Create(Error: T; const Text: string; Code: Int64); reintroduce;
    destructor Destroy; override;
  end;

  ExceptionInvalidReponseError = class(ExceptionAPIRequest);
  ExceptionTryAgain = class(ExceptionAPIRequest);
  ExceptionAuthenticationError = class(ExceptionAPIRequest);
  ExceptionPermissionError = class(ExceptionAPIRequest);

  TAuthorizationScheme = (None, Bearer, Basic, Digest);

  {$WARNINGS OFF}
  TCustomAPI = class
  private
    FBaseUrl: string;

    FCustomHeaders: TNetHeaders;
    FProxySettings: TProxySettings;
    FConnectionTimeout: Integer;
    FSendTimeout: Integer;
    FResponseTimeout: Integer;
    FNeedCheckToken: Boolean;
    FOnAuthErrorCallback: TFunc<Boolean>;
    FAuthScheme: TAuthorizationScheme;
    FAuthValue: string;

    procedure SetBaseUrl(const Value: string);
    procedure SetCustomHeaders(const Value: TNetHeaders);
    procedure SetProxySettings(const Value: TProxySettings);
    procedure SetConnectionTimeout(const Value: Integer);
    procedure SetResponseTimeout(const Value: Integer);
    procedure SetSendTimeout(const Value: Integer);
    procedure SetNeedCheckToken(const Value: Boolean);
    procedure SetOnAuthErrorCallback(const Value: TFunc<Boolean>);
    function CanRequery: Boolean;
  protected
    procedure ParseAndRaiseError(const Code: Int64; const ResponseText: string); virtual;
    function GetHeaders: TNetHeaders; virtual;
    function GetClient: THTTPClient; virtual;
    function GetRequestURL(const Path: string): string;
    function Get(const Path: string; Response: TStream): Integer; overload;
    function Delete(const Path: string; Response: TStream): Integer; overload;
    function Post(const Path: string; Response: TStream): Integer; overload;
    function Post(const Path: string; Body: TJSONObject; Response: TStream; OnReceiveData: TReceiveDataCallback = nil): Integer; overload;
    function Post(const Path: string; Body: TMultipartFormData; Response: TStream): Integer; overload;
    function ParseResponse<T: class, constructor>(const Code: Int64; const ResponseText: string): T;
    procedure CheckAPI;
    function ParamsToPairs(Params: TJSONParam): TArray<string>;
  public
    function Get<TResult: class, constructor>(const Path: string): TResult; overload;
    function Get<TResult: class, constructor; TParams: TJSONParam>(const Path: string; ParamProc: TProc<TParams>): TResult; overload;
    function GetFile(const Path: string; Response: TStream): Integer; overload;
    function GetFile<TParams: TJSONParam>(const Path: string; ParamProc: TProc<TParams>; Response: TStream): Integer; overload;
    function Delete<TResult: class, constructor>(const Path: string): TResult; overload;
    function Patch(const Path: string; Body: TJSONObject; Response: TStream; OnReceiveData: TReceiveDataCallback = nil): Integer; overload;
    function Patch<TResult: class, constructor; TParams: TJSONParam>(const Path: string; ParamProc: TProc<TParams>): TResult; overload;
    function Post<TParams: TJSONParam>(const Path: string; ParamProc: TProc<TParams>; Response: TStream; Event: TReceiveDataCallback = nil): Boolean; overload;
    function Post<TResult: class, constructor; TParams: TJSONParam>(const Path: string; ParamProc: TProc<TParams>): TResult; overload;
    function Post<TResult: class, constructor>(const Path: string): TResult; overload;
    function PostForm<TResult: class, constructor; TParams: TFastMultipartFormData, constructor>(const Path: string; ParamProc: TProc<TParams>): TResult; overload;
  public
    constructor Create; overload; virtual;
    constructor Create(const AuthScheme: TAuthorizationScheme; const AuthValue: string = ''); overload; virtual;
    destructor Destroy; override;
    property BaseUrl: string read FBaseUrl write SetBaseUrl;
    property NeedCheckToken: Boolean read FNeedCheckToken write SetNeedCheckToken;
    property OnAuthErrorCallback: TFunc<Boolean> read FOnAuthErrorCallback write SetOnAuthErrorCallback;
    property AuthScheme: TAuthorizationScheme read FAuthScheme write FAuthScheme;
    property AuthValue: string read FAuthValue write FAuthValue;
    property ProxySettings: TProxySettings read FProxySettings write SetProxySettings;
    /// <summary> Property to set/get the ConnectionTimeout. Value is in milliseconds.
    ///  -1 - Infinite timeout. 0 - platform specific timeout. Supported by Windows, Linux, Android platforms. </summary>
    property ConnectionTimeout: Integer read FConnectionTimeout write SetConnectionTimeout;
    /// <summary> Property to set/get the SendTimeout. Value is in milliseconds.
    ///  -1 - Infinite timeout. 0 - platform specific timeout. Supported by Windows, macOS platforms. </summary>
    property SendTimeout: Integer read FSendTimeout write SetSendTimeout;
    /// <summary> Property to set/get the ResponseTimeout. Value is in milliseconds.
    ///  -1 - Infinite timeout. 0 - platform specific timeout. Supported by all platforms. </summary>
    property ResponseTimeout: Integer read FResponseTimeout write SetResponseTimeout;
    property CustomHeaders: TNetHeaders read FCustomHeaders write SetCustomHeaders;
  end;
  {$WARNINGS ON}

  TCustomAPI<TErrorClass: class, constructor> = class(TCustomAPI)
  protected
    procedure ParseAndRaiseError(const Code: Int64; const ResponseText: string); override;
  end;

  TAPIRoute = class
  private
    FAPI: TCustomAPI;
    procedure SetAPI(const Value: TCustomAPI);
  public
    property API: TCustomAPI read FAPI write SetAPI;
    constructor CreateRoute(AAPI: TCustomAPI);
  end;

const
  DATE_FORMAT = 'YYYY-MM-DD';
  TIME_FORMAT = 'HH:NN:SS';
  DATE_TIME_FORMAT = DATE_FORMAT + ' ' + TIME_FORMAT;

implementation

uses
  REST.Json, System.NetConsts, System.DateUtils;

constructor TCustomAPI.Create;
begin
  inherited;
  // Defaults
  FConnectionTimeout := TURLClient.DefaultConnectionTimeout;
  FSendTimeout := TURLClient.DefaultSendTimeout;
  FResponseTimeout := TURLClient.DefaultResponseTimeout;
  FAuthScheme := TAuthorizationScheme.Bearer;
  FAuthValue := '';
  FBaseUrl := '';
  FNeedCheckToken := False;
end;

constructor TCustomAPI.Create(const AuthScheme: TAuthorizationScheme; const AuthValue: string);
begin
  Create;
  FAuthScheme := AuthScheme;
  FAuthValue := AuthValue;
end;

destructor TCustomAPI.Destroy;
begin
  inherited;
end;

function TCustomAPI.Post(const Path: string; Body: TJSONObject; Response: TStream; OnReceiveData: TReceiveDataCallback): Integer;
begin
  CheckAPI;
  var Client := GetClient;
  try
    var Headers := GetHeaders + [TNetHeader.Create('Content-Type', 'application/json')];
    var Stream := TStringStream.Create;
    Client.ReceiveDataCallBack := OnReceiveData;
    try
      Stream.WriteString(Body.ToJSON);
      Stream.Position := 0;
      Result := Client.Post(GetRequestURL(Path), Stream, Response, Headers).StatusCode;
      if (Result = 401) and CanRequery then
      begin
        Response.Size := 0;
        Result := Client.Post(GetRequestURL(Path), Stream, Response, Headers).StatusCode;
      end;
    finally
      Client.OnReceiveData := nil;
      Stream.Free;
    end;
  finally
    Client.Free;
  end;
end;

function TCustomAPI.Patch(const Path: string; Body: TJSONObject; Response: TStream; OnReceiveData: TReceiveDataCallback): Integer;
begin
  CheckAPI;
  var Client := GetClient;
  try
    var Headers := GetHeaders + [TNetHeader.Create('Content-Type', 'application/json')];
    var Stream := TStringStream.Create;
    Client.ReceiveDataCallBack := OnReceiveData;
    try
      Stream.WriteString(Body.ToJSON);
      Stream.Position := 0;
      Result := Client.Patch(GetRequestURL(Path), Stream, Response, Headers).StatusCode;
      if (Result = 401) and CanRequery then
      begin
        Response.Size := 0;
        Result := Client.Patch(GetRequestURL(Path), Stream, Response, Headers).StatusCode;
      end;
    finally
      Client.OnReceiveData := nil;
      Stream.Free;
    end;
  finally
    Client.Free;
  end;
end;

function TCustomAPI.Get(const Path: string; Response: TStream): Integer;
begin
  CheckAPI;
  var Client := GetClient;
  try
    Result := Client.Get(GetRequestURL(Path), Response, GetHeaders).StatusCode;
    if (Result = 401) and CanRequery then
    begin
      Response.Size := 0;
      Result := Client.Get(GetRequestURL(Path), Response, GetHeaders).StatusCode;
    end;
  finally
    Client.Free;
  end;
end;

function TCustomAPI.Post(const Path: string; Body: TMultipartFormData; Response: TStream): Integer;
begin
  CheckAPI;
  var Client := GetClient;
  try
    Result := Client.Post(GetRequestURL(Path), Body, Response, GetHeaders).StatusCode;
    if (Result = 401) and CanRequery then
    begin
      Response.Size := 0;
      Result := Client.Post(GetRequestURL(Path), Body, Response, GetHeaders).StatusCode;
    end;
  finally
    Client.Free;
  end;
end;

function TCustomAPI.Post(const Path: string; Response: TStream): Integer;
begin
  CheckAPI;
  var Client := GetClient;
  try
    Result := Client.Post(GetRequestURL(Path), TStream(nil), Response, GetHeaders).StatusCode;
    if (Result = 401) and CanRequery then
    begin
      Response.Size := 0;
      Result := Client.Post(GetRequestURL(Path), TStream(nil), Response, GetHeaders).StatusCode;
    end;
  finally
    Client.Free;
  end;
end;

function TCustomAPI.Post<TResult, TParams>(const Path: string; ParamProc: TProc<TParams>): TResult;
begin
  var Response := TStringStream.Create('', TEncoding.UTF8);
  var Params := TParams.Create;
  try
    if Assigned(ParamProc) then
      ParamProc(Params);
    Result := ParseResponse<TResult>(Post(Path, Params.JSON, Response), Response.DataString);
  finally
    Params.Free;
    Response.Free;
  end;
end;

function TCustomAPI.Patch<TResult, TParams>(const Path: string; ParamProc: TProc<TParams>): TResult;
begin
  var Response := TStringStream.Create('', TEncoding.UTF8);
  var Params := TParams.Create;
  try
    if Assigned(ParamProc) then
      ParamProc(Params);
    Result := ParseResponse<TResult>(Patch(Path, Params.JSON, Response), Response.DataString);
  finally
    Params.Free;
    Response.Free;
  end;
end;

function TCustomAPI.Post<TParams>(const Path: string; ParamProc: TProc<TParams>; Response: TStream; Event: TReceiveDataCallback): Boolean;
begin
  var Params := TParams.Create;
  try
    if Assigned(ParamProc) then
      ParamProc(Params);
    var Code := Post(Path, Params.JSON, Response, Event);
    case Code of
      200..299:
        Result := True;
    else
      Result := False;
      var Strings := TStringStream.Create;
      try
        Response.Position := 0;
        Strings.LoadFromStream(Response);
        ParseAndRaiseError(Code, Strings.DataString);
      finally
        Strings.Free;
      end;
    end;
  finally
    Params.Free;
  end;
end;

function TCustomAPI.Post<TResult>(const Path: string): TResult;
begin
  var Response := TStringStream.Create('', TEncoding.UTF8);
  try
    Result := ParseResponse<TResult>(Post(Path, Response), Response.DataString);
  finally
    Response.Free;
  end;
end;

function TCustomAPI.Delete(const Path: string; Response: TStream): Integer;
begin
  CheckAPI;
  var Client := GetClient;
  try
    Result := Client.Delete(GetRequestURL(Path), Response, GetHeaders).StatusCode;
    if (Result = 401) and CanRequery then
    begin
      Response.Size := 0;
      Result := Client.Delete(GetRequestURL(Path), Response, GetHeaders).StatusCode;
    end;
  finally
    Client.Free;
  end;
end;

function TCustomAPI.Delete<TResult>(const Path: string): TResult;
begin
  var Response := TStringStream.Create('', TEncoding.UTF8);
  try
    Result := ParseResponse<TResult>(Delete(Path, Response), Response.DataString);
  finally
    Response.Free;
  end;
end;

function TCustomAPI.PostForm<TResult, TParams>(const Path: string; ParamProc: TProc<TParams>): TResult;
begin
  var Response := TStringStream.Create('', TEncoding.UTF8);
  var Params := TParams.Create;
  try
    if Assigned(ParamProc) then
      ParamProc(Params);
    Result := ParseResponse<TResult>(Post(Path, Params, Response), Response.DataString);
  finally
    Params.Free;
    Response.Free;
  end;
end;

function TCustomAPI.Get<TResult, TParams>(const Path: string; ParamProc: TProc<TParams>): TResult;
begin
  var Response := TStringStream.Create('', TEncoding.UTF8);
  var QPath := Path;
  if Assigned(ParamProc) then
  begin
    var Params := TParams.Create;
    try
      ParamProc(Params);
      var Pairs := ParamsToPairs(Params);
      if Length(Pairs) > 0 then
        QPath := QPath + '?' + string.Join('&', Pairs);
    finally
      Params.Free;
    end;
  end;
  try
    Result := ParseResponse<TResult>(Get(QPath, Response), Response.DataString);
  finally
    Response.Free;
  end;
end;

function TCustomAPI.Get<TResult>(const Path: string): TResult;
begin
  var Response := TStringStream.Create('', TEncoding.UTF8);
  try
    Result := ParseResponse<TResult>(Get(Path, Response), Response.DataString);
  finally
    Response.Free;
  end;
end;

function TCustomAPI.GetClient: THTTPClient;
begin
  Result := THTTPClient.Create;
  Result.ProxySettings := FProxySettings;
  Result.ConnectionTimeout := FConnectionTimeout;
  Result.ResponseTimeout := FResponseTimeout;
  {$IF RTLVersion >= 35.0}
  Result.SendTimeout := FSendTimeout;
  {$ENDIF}
  Result.AcceptCharSet := 'utf-8';
end;

function TCustomAPI.GetFile(const Path: string; Response: TStream): Integer;
begin
  Result := GetFile<TJSONParam>(Path, nil, Response);
end;

function TCustomAPI.GetFile<TParams>(const Path: string; ParamProc: TProc<TParams>; Response: TStream): Integer;
begin
  CheckAPI;
  var Client := GetClient;
  try
    var QPath := GetRequestURL(Path);
    if Assigned(ParamProc) then
    begin
      var Params := TParams.Create;
      try
        ParamProc(Params);
        var Pairs := ParamsToPairs(Params);
        if Length(Pairs) > 0 then
          QPath := QPath + '?' + string.Join('&', Pairs);
      finally
        Params.Free;
      end;
    end;

    Result := Client.Get(QPath, Response, GetHeaders).StatusCode;
    if (Result = 401) and CanRequery then
    begin
      Response.Size := 0;
      Result := Client.Get(QPath, Response, GetHeaders).StatusCode;
    end;
    case Result of
      200..299:
        ; {success}
    else
      var Strings := TStringStream.Create;
      try
        Response.Position := 0;
        Strings.LoadFromStream(Response);
        ParseAndRaiseError(Result, Strings.DataString);
      finally
        Strings.Free;
      end;
    end;
  finally
    Client.Free;
  end;
end;

function TCustomAPI.GetHeaders: TNetHeaders;
begin
  Result := [];
  if not FAuthValue.IsEmpty then
  begin
    var AuthData := '';
    case FAuthScheme of
      None:
        AuthData := FAuthValue;
      Bearer:
        AuthData := 'Bearer ' + FAuthValue;
      Basic:
        AuthData := 'Basic ' + FAuthValue;
      Digest:
        AuthData := 'Digest ' + FAuthValue;
    end;
    Result := Result + [TNetHeader.Create('Authorization', AuthData)];
  end;
  Result := Result + FCustomHeaders;
end;

function TCustomAPI.GetRequestURL(const Path: string): string;
begin
  if Path.ToLower.StartsWith('http') then
    Exit(Path);
  Result := FBaseURL + '/' + Path;
end;

function TCustomAPI.CanRequery: Boolean;
begin
  Result := Assigned(FOnAuthErrorCallback);
  if Result then
    Result := FOnAuthErrorCallback;
end;

procedure TCustomAPI.CheckAPI;
begin
  if FNeedCheckToken and FAuthValue.IsEmpty then
    raise ExceptionAPI.Create('Token is empty!');
  if FBaseUrl.IsEmpty then
    raise ExceptionAPI.Create('Base url is empty!');
end;

function TCustomAPI.ParamsToPairs(Params: TJSONParam): TArray<string>;
begin
  Result := [];
  for var Pair in Params.ToStringPairs do
    Result := Result + [Pair.Key + '=' + Pair.Value];
end;

procedure TCustomAPI.ParseAndRaiseError(const Code: Int64; const ResponseText: string);
begin
  case Code of
    401:
      raise ExceptionAuthenticationError.Create(ResponseText, Code);
    403:
      raise ExceptionPermissionError.Create(ResponseText, Code);
    409:
      raise ExceptionTryAgain.Create(ResponseText, Code);
  else
    raise ExceptionAPIRequest.Create(ResponseText, Code);
  end;
end;

function TCustomAPI.ParseResponse<T>(const Code: Int64; const ResponseText: string): T;
begin
  Result := nil;
  try
    case Code of
      200..299:
        Result := TJson.JsonToObject<T>(ResponseText);
    else
      raise ExceptionInvalidReponseError.Create(ResponseText, Code);
    end;
  except
    ParseAndRaiseError(Code, ResponseText);
  end;
end;

procedure TCustomAPI.SetBaseUrl(const Value: string);
begin
  FBaseUrl := Value;
end;

procedure TCustomAPI.SetConnectionTimeout(const Value: Integer);
begin
  FConnectionTimeout := Value;
end;

procedure TCustomAPI.SetCustomHeaders(const Value: TNetHeaders);
begin
  FCustomHeaders := Value;
end;

procedure TCustomAPI.SetNeedCheckToken(const Value: Boolean);
begin
  FNeedCheckToken := Value;
end;

procedure TCustomAPI.SetOnAuthErrorCallback(const Value: TFunc<Boolean>);
begin
  FOnAuthErrorCallback := Value;
end;

procedure TCustomAPI.SetProxySettings(const Value: TProxySettings);
begin
  FProxySettings := Value;
end;

procedure TCustomAPI.SetResponseTimeout(const Value: Integer);
begin
  FResponseTimeout := Value;
end;

procedure TCustomAPI.SetSendTimeout(const Value: Integer);
begin
  FSendTimeout := Value;
end;

{ ExceptionAPIRequest }

constructor ExceptionAPIRequest.Create(const Text: string; Code: Int64);
begin
  inherited Create(Text);
  Self.FText := Text;
  Self.Code := Code;
end;

{ TAPIRoute }

constructor TAPIRoute.CreateRoute(AAPI: TCustomAPI);
begin
  inherited Create;
  FAPI := AAPI;
end;

procedure TAPIRoute.SetAPI(const Value: TCustomAPI);
begin
  FAPI := Value;
end;

{ TJSONInterceptorStringToString }

constructor TJSONInterceptorStringToString.Create;
begin
  ConverterType := ctString;
  ReverterType := rtString;
end;

{ Fetch }

type
  Fetch<T> = class
    type
      TFetchProc = reference to procedure(const Element: T);
  public
    class procedure All(const Items: TArray<T>; Proc: TFetchProc);
  end;

{ Fetch<T> }

class procedure Fetch<T>.All(const Items: TArray<T>; Proc: TFetchProc);
begin
  for var Item in Items do
    Proc(Item);
end;

{ TJSONParam }

function TJSONParam.Add(const Key, Value: string): TJSONParam;
begin
  Delete(Key);
  FJSON.AddPair(Key, Value);
  Result := Self;
end;

function TJSONParam.Add(const Key: string; const Value: TJSONValue): TJSONParam;
begin
  Delete(Key);
  FJSON.AddPair(Key, Value);
  Result := Self;
end;

function TJSONParam.Add(const Key: string; const Value: TJSONParam): TJSONParam;
begin
  try
    Add(Key, Value.JSON);
    Value.JSON := nil;
  finally
    Value.Free;
  end;
  Result := Self;
end;

function TJSONParam.Add(const Key: string; const Value: TDateTime; Format: string): TJSONParam;
begin
  if Format.IsEmpty then
    Format := DATE_TIME_FORMAT;
  Add(Key, FormatDateTime(Format, System.DateUtils.TTimeZone.local.ToUniversalTime(Value)));
  Result := Self;
end;

function TJSONParam.Add(const Key: string; const Value: Boolean): TJSONParam;
begin
  Add(Key, TJSONBool.Create(Value));
  Result := Self;
end;

function TJSONParam.Add(const Key: string; const Value: Integer): TJSONParam;
begin
  Add(Key, TJSONNumber.Create(Value));
  Result := Self;
end;

function TJSONParam.Add(const Key: string; const Value: Extended): TJSONParam;
begin
  Add(Key, TJSONNumber.Create(Value));
  Result := Self;
end;

function TJSONParam.Add(const Key: string; Value: TArray<TJSONValue>): TJSONParam;
begin
  var JArr := TJSONArray.Create;
  Fetch<TJSONValue>.All(Value, JArr.AddElement);
  Add(Key, JArr);
  Result := Self;
end;

function TJSONParam.Add(const Key: string; Value: TArray<TJSONParam>): TJSONParam;
begin
  try
    var JArr := TJSONArray.Create;
    for var Item in Value do
    begin
      JArr.AddElement(Item.JSON);
      Item.JSON := nil;
    end;

    Add(Key, JArr);
  finally
    for var Item in Value do
      Item.Free;
  end;
  Result := Self;
end;

function TJSONParam.Add(const Key: string; Value: TArray<Extended>): TJSONParam;
begin
  var JArr := TJSONArray.Create;
  for var Item in Value do
    JArr.Add(Item);

  Add(Key, JArr);
  Result := Self;
end;

function TJSONParam.Add(const Key: string; Value: TArray<Integer>): TJSONParam;
begin
  var JArr := TJSONArray.Create;
  for var Item in Value do
    JArr.Add(Item);

  Add(Key, JArr);
  Result := Self;
end;

function TJSONParam.Add(const Key: string; Value: TArray<string>): TJSONParam;
begin
  var JArr := TJSONArray.Create;
  for var Item in Value do
    JArr.Add(Item);

  Add(Key, JArr);
  Result := Self;
end;

procedure TJSONParam.Clear;
begin
  FJSON.Free;
  FJSON := TJSONObject.Create;
end;

constructor TJSONParam.Create;
begin
  FJSON := TJSONObject.Create;
end;

procedure TJSONParam.Delete(const Key: string);
begin
  var Item := FJSON.RemovePair(Key);
  if Assigned(Item) then
    Item.Free;
end;

destructor TJSONParam.Destroy;
begin
  if Assigned(FJSON) then
    FJSON.Free;
  inherited;
end;

function TJSONParam.GetCount: Integer;
begin
  Result := FJSON.Count;
end;

function TJSONParam.GetOrCreate<T>(const Name: string): T;
begin
  if not FJSON.TryGetValue<T>(Name, Result) then
  begin
    Result := T.Create;
    FJSON.AddPair(Name, Result);
  end;
end;

function TJSONParam.GetOrCreateObject(const Name: string): TJSONObject;
begin
  Result := GetOrCreate<TJSONObject>(Name);
end;

procedure TJSONParam.SetJSON(const Value: TJSONObject);
begin
  FJSON := Value;
end;

function TJSONParam.ToJsonString(FreeObject: Boolean): string;
begin
  Result := FJSON.ToJSON;
  if FreeObject then
    Free;
end;

function TJSONParam.ToStream: TStringStream;
begin
  Result := TStringStream.Create;
  try
    Result.WriteString(ToJsonString);
    Result.Position := 0;
  except
    Result.Free;
    raise;
  end;
end;

function TJSONParam.ToStringPairs: TArray<TPair<string, string>>;
begin
  for var Pair in FJSON do
    Result := Result + [TPair<string, string>.Create(Pair.JsonString.Value, Pair.JsonValue.AsType<string>)];
end;

{ TFastMultipartFormData }

constructor TFastMultipartFormData.Create;
begin
  inherited Create(True);
end;

{ TCustomAPI<TErrorClass> }

procedure TCustomAPI<TErrorClass>.ParseAndRaiseError(const Code: Int64; const ResponseText: string);
begin
  var Error: TErrorClass := nil;
  try
    Error := TJson.JsonToObject<TErrorClass>(ResponseText);
    if Error = nil then
      Error := TErrorClass.Create;
  except
    inherited;
  end;
  raise ExceptionAPIRequest<TErrorClass>.Create(Error, ResponseText, Code);
end;

{ ExceptionAPIRequest<T> }

constructor ExceptionAPIRequest<T>.Create(Error: T; const Text: string; Code: Int64);
begin
  inherited Create(Text, Code);
  FError := Error;
end;

destructor ExceptionAPIRequest<T>.Destroy;
begin
  FError.Free;
  inherited;
end;

end.

