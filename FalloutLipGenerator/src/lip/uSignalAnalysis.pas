(*
  Fallout Lip Generator - Signal Analysis Unit
  
  This unit provides audio signal analysis for lip-sync generation.
  Implements envelope detection, silence detection, and energy-based
  phoneme approximation for generating mouth movement timing.
  
  Copyright (c) 2026
  License: MIT
*)

unit uSignalAnalysis;

interface

uses
  Classes, SysUtils, Math, Types, uAudioBuffer;

type
  { Mouth states (visemes) }
  TMouthState = (
    msClosed,      // Mouth closed / silence
    msSmallOpen,   // Slight opening (e.g., 'm', 'b', 'p')
    msMediumOpen,  // Medium opening (e.g., 'n', 'd', 't')
    msWideOpen     // Wide opening (e.g., 'a', 'o', 'e')
  );

  { Lip frame - represents mouth state at a specific time }
  TLipFrame = record
    Time: Double;          // Time in seconds
    MouthState: TMouthState; // Mouth state
    Intensity: Double;     // Intensity (0.0 to 1.0)
    Duration: Double;      // Duration of this frame
  end;

  { Array of lip frames }
  TLipFrameArray = array of TLipFrame;
  TDoubleArray = array of Double;
  TBooleanArray = array of Boolean;
  TPointFArray = array of TPointF;
  TMouthStateArray = array of TMouthState;

  { Envelope detector for amplitude tracking }
  TEnvelopeDetector = class
  private
    FAttackTime: Double;    // Attack time constant (seconds)
    FReleaseTime: Double;   // Release time constant (seconds)
    FSampleRate: Integer;
    FCurrentEnvelope: Double;
    FThreshold: Double;
    
    function CalculateAlpha(timeConstant: Double): Double;
  public
    constructor Create(sampleRate: Integer);
    
    { Process a single sample, return envelope value }
    function ProcessSample(sample: Double): Double;
    
    { Process entire buffer, return envelope array }
    function ProcessBuffer(buffer: TAudioBuffer): TDoubleArray;
    
    { Reset envelope state }
    procedure Reset;
    
    property AttackTime: Double read FAttackTime write FAttackTime;
    property ReleaseTime: Double read FReleaseTime write FReleaseTime;
    property Threshold: Double read FThreshold write FThreshold;
  end;

  { Audio analyzer for lip-sync generation }
  TAudioAnalyzer = class
  private
    FSampleRate: Integer;
    FWindowSize: Integer;
    FHopSize: Integer;
    FThreshold: Double;
    FMinSilenceDuration: Double;
    FMinPhonemeDuration: Double;
    
    function CalculateRMS(const samples: array of Double; startIdx, endIdx: Integer): Double;
    function FindZeroCrossingRate(const samples: array of Double; startIdx, endIdx: Integer): Double;
    function EstimateSpectralCentroid(const samples: array of Double; startIdx, endIdx: Integer): Double;
    function MapEnergyToMouthState(energy: Double): TMouthState;
    function MapEnergyToIntensity(energy: Double): Double;
    function DetectSilenceRegions(const envelope: array of Double): TBooleanArray;
    procedure SmoothMouthStates(var states: TLipFrameArray);
  public
    constructor Create(sampleRate: Integer);
    
    { Analyze audio and generate lip frames }
    function GenerateLipFrames(buffer: TAudioBuffer; fps: Integer): TLipFrameArray;
    
    { Detect phoneme-like segments }
    function DetectPhonemeSegments(buffer: TAudioBuffer): TPointFArray;
    
    { Calculate energy envelope }
    function CalculateEnergyEnvelope(buffer: TAudioBuffer): TDoubleArray;
    
    { Detect silence regions }
    function DetectSilence(buffer: TAudioBuffer; threshold: Double): TPointFArray;
    
    { Get amplitude envelope }
    function GetAmplitudeEnvelope(buffer: TAudioBuffer; windowSize: Integer): TDoubleArray;
    
    { Properties }
    property Threshold: Double read FThreshold write FThreshold;
    property MinSilenceDuration: Double read FMinSilenceDuration write FMinSilenceDuration;
    property MinPhonemeDuration: Double read FMinPhonemeDuration write FMinPhonemeDuration;
    property WindowSize: Integer read FWindowSize write FWindowSize;
    property HopSize: Integer read FHopSize write FHopSize;
  end;

  { Utility functions }
  function MouthStateToString(state: TMouthState): string;
  function StringToMouthState(const str: string): TMouthState;
  function MouthStateToIndex(state: TMouthState): Integer;
  function IndexToMouthState(index: Integer): TMouthState;

  { Text-to-phoneme mappings based on VOCK }
  function LetterToLipCode(C: Char): Byte;
  function DigraphToLipCode(const S: string): Byte;
  function TextToLipCodes(const Text: string; Duration: Double): TLipFrameArray;

implementation

const
  LETTER_TO_LIP_MAP: array[0..25] of record
    Letter: Char;
    Code: Byte;
  end = (
    (Letter: 'a'; Code: $0A), (Letter: 'b'; Code: $10), (Letter: 'c'; Code: $11),
    (Letter: 'd'; Code: $11), (Letter: 'e'; Code: $06), (Letter: 'f'; Code: $13),
    (Letter: 'g'; Code: $11), (Letter: 'h'; Code: $0F), (Letter: 'i'; Code: $08),
    (Letter: 'j'; Code: $13), (Letter: 'k'; Code: $11), (Letter: 'l'; Code: $12),
    (Letter: 'm'; Code: $10), (Letter: 'n'; Code: $11), (Letter: 'o'; Code: $04),
    (Letter: 'p'; Code: $10), (Letter: 'q'; Code: $11), (Letter: 'r'; Code: $12),
    (Letter: 's'; Code: $13), (Letter: 't'; Code: $11), (Letter: 'u'; Code: $05),
    (Letter: 'v'; Code: $13), (Letter: 'w'; Code: $12), (Letter: 'x'; Code: $13),
    (Letter: 'y'; Code: $12), (Letter: 'z'; Code: $13)
  );

  DIGRAPH_TO_LIP_MAP: array[0..7] of record
    Digraph: string[2];
    Code: Byte;
  end = (
    (Digraph: 'ch'; Code: $13), (Digraph: 'dh'; Code: $13), (Digraph: 'ng'; Code: $11),
    (Digraph: 'ph'; Code: $13), (Digraph: 'sh'; Code: $13), (Digraph: 'th'; Code: $13),
    (Digraph: 'wh'; Code: $12), (Digraph: 'zh'; Code: $13)
  );

function LetterToLipCode(C: Char): Byte;
var
  I: Integer;
  L: Char;
begin
  L := LowerCase(C)[1];
  for I := 0 to High(LETTER_TO_LIP_MAP) do
    if LETTER_TO_LIP_MAP[I].Letter = L then
      Exit(LETTER_TO_LIP_MAP[I].Code);
  Result := $0E;
end;

function DigraphToLipCode(const S: string): Byte;
var
  I: Integer;
begin
  for I := 0 to High(DIGRAPH_TO_LIP_MAP) do
    if S = DIGRAPH_TO_LIP_MAP[I].Digraph then
      Exit(DIGRAPH_TO_LIP_MAP[I].Code);
  Result := 0;
end;

function TextToLipCodes(const Text: string; Duration: Double): TLipFrameArray;
var
  I, J: Integer;
  CleanText: string;
  Codes: array of Byte;
  LastCode: Byte;
  Code: Byte;
begin
  Result := nil;
  CleanText := LowerCase(Text);
  for I := Length(CleanText) downto 1 do
    if not (CleanText[I] in ['a'..'z', ' ']) then
      Delete(CleanText, I, 1);

  SetLength(Codes, 0);
  I := 1;
  while I <= Length(CleanText) do
  begin
    if CleanText[I] = ' ' then
    begin
      Inc(I);
      Continue;
    end;
    if I < Length(CleanText) then
    begin
      Code := DigraphToLipCode(CleanText[I] + CleanText[I + 1]);
      if Code <> 0 then
      begin
        SetLength(Codes, Length(Codes) + 1);
        Codes[High(Codes)] := Code;
        Inc(I, 2);
        Continue;
      end;
    end;
    Code := LetterToLipCode(CleanText[I]);
    SetLength(Codes, Length(Codes) + 1);
    Codes[High(Codes)] := Code;
    Inc(I);
  end;

  if Length(Codes) = 0 then
    Exit;

  LastCode := 0;
  J := 0;
  for I := 0 to High(Codes) do
  begin
    if (I = 0) or (Codes[I] <> LastCode) then
    begin
      LastCode := Codes[I];
      SetLength(Result, J + 1);
      Result[J].Time := I * (Duration / Length(Codes));
      Result[J].Duration := Duration / Length(Codes);
      Result[J].Intensity := 0.8;
      case Codes[I] of
        $10, $11: Result[J].MouthState := msSmallOpen;
        $12: Result[J].MouthState := msMediumOpen;
        $13: Result[J].MouthState := msWideOpen;
      else
        Result[J].MouthState := msClosed;
      end;
      Inc(J);
    end;
  end;
end;

{ TEnvelopeDetector }

constructor TEnvelopeDetector.Create(sampleRate: Integer);
begin
  inherited Create;
  FSampleRate := sampleRate;
  FAttackTime := 0.01;    // 10ms attack
  FReleaseTime := 0.1;    // 100ms release
  FThreshold := 0.05;
  FCurrentEnvelope := 0.0;
end;

function TEnvelopeDetector.CalculateAlpha(timeConstant: Double): Double;
begin
  if timeConstant > 0 then
    Result := Exp(-1.0 / (timeConstant * FSampleRate))
  else
    Result := 0.0;
end;

function TEnvelopeDetector.ProcessSample(sample: Double): Double;
var
  absSample, alpha: Double;
begin
  absSample := Abs(sample);
  
  if absSample > FCurrentEnvelope then
  begin
    { Attack phase }
    alpha := CalculateAlpha(FAttackTime);
    FCurrentEnvelope := alpha * FCurrentEnvelope + (1.0 - alpha) * absSample;
  end
  else
  begin
    { Release phase }
    alpha := CalculateAlpha(FReleaseTime);
    FCurrentEnvelope := alpha * FCurrentEnvelope;
  end;
  
  Result := FCurrentEnvelope;
end;

function TEnvelopeDetector.ProcessBuffer(buffer: TAudioBuffer): TDoubleArray;
var
  I, sampleCount: Integer;
begin
  sampleCount := buffer.SampleCount;
  SetLength(Result, sampleCount);
  
  Reset;
  
  for I := 0 to sampleCount - 1 do
    Result[I] := ProcessSample(buffer[I]);
end;

procedure TEnvelopeDetector.Reset;
begin
  FCurrentEnvelope := 0.0;
end;

{ TAudioAnalyzer }

constructor TAudioAnalyzer.Create(sampleRate: Integer);
begin
  inherited Create;
  FSampleRate := sampleRate;
  FWindowSize := Round(sampleRate * 0.02);  // 20ms window
  FHopSize := Round(sampleRate * 0.01);     // 10ms hop
  FThreshold := 0.08;
  FMinSilenceDuration := 0.1;  // 100ms minimum silence
  FMinPhonemeDuration := 0.05; // 50ms minimum phoneme
end;

function TAudioAnalyzer.CalculateRMS(const samples: array of Double; startIdx, endIdx: Integer): Double;
var
  I, count: Integer;
  sumSquares: Double;
begin
  if startIdx < 0 then startIdx := 0;
  if endIdx >= Length(samples) then endIdx := Length(samples) - 1;
  if startIdx > endIdx then Exit(0.0);
  
  count := endIdx - startIdx + 1;
  sumSquares := 0.0;
  
  for I := startIdx to endIdx do
    sumSquares := sumSquares + Sqr(samples[I]);
  
  Result := Sqrt(sumSquares / count);
end;

function TAudioAnalyzer.FindZeroCrossingRate(const samples: array of Double; startIdx, endIdx: Integer): Double;
var
  I, count, crossings: Integer;
begin
  if startIdx < 0 then startIdx := 0;
  if endIdx >= Length(samples) then endIdx := Length(samples) - 1;
  if startIdx >= endIdx then Exit(0.0);
  
  crossings := 0;
  count := endIdx - startIdx;
  
  for I := startIdx to endIdx - 1 do
  begin
    if (samples[I] >= 0) and (samples[I + 1] < 0) or
       (samples[I] < 0) and (samples[I + 1] >= 0) then
      Inc(crossings);
  end;
  
  if count > 0 then
    Result := crossings / count
  else
    Result := 0.0;
end;

function TAudioAnalyzer.EstimateSpectralCentroid(const samples: array of Double; startIdx, endIdx: Integer): Double;
var
  I, count: Integer;
  sumMagnitude, sumWeighted: Double;
  magnitude: Double;
begin
  { Simplified spectral centroid estimation using zero-crossing rate as proxy }
  { In a full implementation, this would use FFT }
  
  if startIdx < 0 then startIdx := 0;
  if endIdx >= Length(samples) then endIdx := Length(samples) - 1;
  if startIdx > endIdx then Exit(0.5);
  
  count := endIdx - startIdx + 1;
  sumMagnitude := 0.0;
  sumWeighted := 0.0;
  
  for I := startIdx to endIdx do
  begin
    magnitude := Abs(samples[I]);
    sumMagnitude := sumMagnitude + magnitude;
    sumWeighted := sumWeighted + magnitude * (I - startIdx) / count;
  end;
  
  if sumMagnitude > 0 then
    Result := sumWeighted / sumMagnitude
  else
    Result := 0.5;
end;

function TAudioAnalyzer.MapEnergyToMouthState(energy: Double): TMouthState;
begin
  if energy < FThreshold * 0.5 then
    Result := msClosed
  else if energy < FThreshold * 1.5 then
    Result := msSmallOpen
  else if energy < FThreshold * 2.5 then
    Result := msMediumOpen
  else
    Result := msWideOpen;
end;

function TAudioAnalyzer.MapEnergyToIntensity(energy: Double): Double;
begin
  if energy < FThreshold * 0.5 then
    Result := 0.0
  else if energy > FThreshold * 3.0 then
    Result := 1.0
  else
    Result := (energy - FThreshold * 0.5) / (FThreshold * 2.5);
  
  Result := EnsureRange(Result, 0.0, 1.0);
end;

function TAudioAnalyzer.DetectSilenceRegions(const envelope: array of Double): TBooleanArray;
var
  I, silenceStart, silenceLength: Integer;
  inSilence: Boolean;
  silenceThreshold: Double;
begin
  SetLength(Result, Length(envelope));
  silenceThreshold := FThreshold * 0.3;
  inSilence := False;
  silenceStart := 0;
  silenceLength := 0;
  
  for I := 0 to Length(envelope) - 1 do
  begin
    if envelope[I] < silenceThreshold then
    begin
      if not inSilence then
      begin
        inSilence := True;
        silenceStart := I;
      end;
      Inc(silenceLength);
      Result[I] := True;
    end
    else
    begin
      if inSilence then
      begin
        { Check if silence was long enough }
        if silenceLength < Round(FMinSilenceDuration * FSampleRate) then
        begin
          { Not long enough, mark as non-silence }
          while silenceStart < I do
          begin
            Result[silenceStart] := False;
            Inc(silenceStart);
          end;
        end;
        inSilence := False;
        silenceLength := 0;
      end;
      Result[I] := False;
    end;
  end;
end;

procedure TAudioAnalyzer.SmoothMouthStates(var states: TLipFrameArray);
var
  I, J, window: Integer;
  state: TMouthState;
  stateCounts: array[TMouthState] of Integer;
  maxState: TMouthState;
  maxCount: Integer;
  smoothed: TMouthStateArray;
begin
  if Length(states) = 0 then Exit;

  window := Round(FMinPhonemeDuration * FSampleRate / (FHopSize * 2));
  if window < 1 then window := 1;

  SetLength(smoothed, Length(states));

  for I := 0 to Length(states) - 1 do
  begin
    { Count states in window }
    for state := Low(TMouthState) to High(TMouthState) do
      stateCounts[state] := 0;

    for J := Max(0, I - window) to Min(Length(states) - 1, I + window) do
      Inc(stateCounts[states[J].MouthState]);

    { Find most common state }
    maxCount := 0;
    maxState := msClosed;
    for state := Low(TMouthState) to High(TMouthState) do
      if stateCounts[state] > maxCount then
      begin
        maxCount := stateCounts[state];
        maxState := state;
      end;

    smoothed[I] := maxState;
  end;

  { Apply smoothed states back }
  for I := 0 to Length(states) - 1 do
    states[I].MouthState := smoothed[I];
end;

function TAudioAnalyzer.GenerateLipFrames(buffer: TAudioBuffer; fps: Integer): TLipFrameArray;
var
  envelope: TDoubleArray;
  silenceRegions: TBooleanArray;
  frameDuration, currentTime: Double;
  sampleIndex, frameCount: Integer;
  frameEnergy: Double;
  currentState, prevState: TMouthState;
  stateStartFrame: Integer;
  I: Integer;
begin
  { Calculate envelope }
  envelope := CalculateEnergyEnvelope(buffer);
  
  { Detect silence regions }
  silenceRegions := DetectSilenceRegions(envelope);
  
  { Calculate frame parameters }
  frameDuration := 1.0 / fps;
  frameCount := Round(buffer.Duration * fps);
  if frameCount < 1 then frameCount := 1;
  
  SetLength(Result, frameCount);
  
  currentTime := 0.0;
  prevState := msClosed;
  stateStartFrame := 0;
  
  for I := 0 to frameCount - 1 do
  begin
    { Calculate average energy for this frame }
    sampleIndex := Round(I * buffer.SampleRate / fps);
    frameEnergy := 0.0;
    
    if sampleIndex < Length(envelope) then
    begin
      frameEnergy := envelope[sampleIndex];
      
      { Check if in silence region }
      if silenceRegions[sampleIndex] then
        currentState := msClosed
      else
        currentState := MapEnergyToMouthState(frameEnergy);
    end
    else
    begin
      currentState := msClosed;
      frameEnergy := 0.0;
    end;
    
    { Apply temporal smoothing }
    if (currentState <> prevState) and (I - stateStartFrame < Round(FMinPhonemeDuration * fps)) then
      currentState := prevState;
    
    { Fill frame }
    Result[I].Time := currentTime;
    Result[I].MouthState := currentState;
    Result[I].Intensity := MapEnergyToIntensity(frameEnergy);
    Result[I].Duration := frameDuration;
    
    currentTime := currentTime + frameDuration;
    
    if currentState <> prevState then
    begin
      prevState := currentState;
      stateStartFrame := I;
    end;
  end;
  
  { Apply final smoothing }
  SmoothMouthStates(Result);
end;

function TAudioAnalyzer.DetectPhonemeSegments(buffer: TAudioBuffer): TPointFArray;
var
  envelope: TDoubleArray;
  silenceRegions: TBooleanArray;
  I, segmentStart: Integer;
  inSegment: Boolean;
  segmentCount: Integer;
  energy: Double;
begin
  envelope := CalculateEnergyEnvelope(buffer);
  silenceRegions := DetectSilenceRegions(envelope);
  segmentStart := 0;
  
  { Count segments }
  segmentCount := 0;
  inSegment := False;
  
  for I := 0 to Length(envelope) - 1 do
  begin
    energy := envelope[I];
    
    if (energy >= FThreshold) and not silenceRegions[I] then
    begin
      if not inSegment then
      begin
        inSegment := True;
        Inc(segmentCount);
      end;
    end
    else
    begin
      inSegment := False;
    end;
  end;
  
  { Allocate result array }
  SetLength(Result, segmentCount * 2); { Start and end points }
  
  { Fill segments }
  segmentCount := 0;
  inSegment := False;
  
  for I := 0 to Length(envelope) - 1 do
  begin
    energy := envelope[I];
    
    if (energy >= FThreshold) and not silenceRegions[I] then
    begin
      if not inSegment then
      begin
        inSegment := True;
        segmentStart := I;
      end;
    end
    else
    begin
      if inSegment then
      begin
        inSegment := False;
        Result[segmentCount].X := segmentStart / FSampleRate;
        Result[segmentCount].Y := I / FSampleRate;
        Inc(segmentCount);
      end;
    end;
  end;
  
  { Handle last segment }
  if inSegment then
  begin
    Result[segmentCount].X := segmentStart / FSampleRate;
    Result[segmentCount].Y := Length(envelope) / FSampleRate;
  end;
end;

function TAudioAnalyzer.CalculateEnergyEnvelope(buffer: TAudioBuffer): TDoubleArray;
var
  detector: TEnvelopeDetector;
begin
  detector := TEnvelopeDetector.Create(FSampleRate);
  try
    detector.AttackTime := 0.01;
    detector.ReleaseTime := 0.1;
    detector.Threshold := FThreshold;
    Result := detector.ProcessBuffer(buffer);
  finally
    detector.Free;
  end;
end;

function TAudioAnalyzer.DetectSilence(buffer: TAudioBuffer; threshold: Double): TPointFArray;
var
  envelope: TDoubleArray;
  I, silenceStart: Integer;
  inSilence: Boolean;
  silenceCount: Integer;
  oldThreshold: Double;
begin
  oldThreshold := FThreshold;
  FThreshold := threshold;
  silenceStart := 0;
  
  try
    envelope := CalculateEnergyEnvelope(buffer);
    
    { Count silence segments }
    silenceCount := 0;
    inSilence := False;
    
    for I := 0 to Length(envelope) - 1 do
    begin
      if envelope[I] < threshold then
      begin
        if not inSilence then
        begin
          inSilence := True;
          Inc(silenceCount);
        end;
      end
      else
      begin
        inSilence := False;
      end;
    end;
    
    { Allocate result }
    SetLength(Result, silenceCount * 2);
    
    { Fill silence segments }
    silenceCount := 0;
    inSilence := False;
    
    for I := 0 to Length(envelope) - 1 do
    begin
      if envelope[I] < threshold then
      begin
        if not inSilence then
        begin
          inSilence := True;
          silenceStart := I;
        end;
      end
      else
      begin
        if inSilence then
        begin
          inSilence := False;
          Result[silenceCount].X := silenceStart / FSampleRate;
          Result[silenceCount].Y := I / FSampleRate;
          Inc(silenceCount);
        end;
      end;
    end;
    
    { Handle last silence }
    if inSilence then
    begin
      Result[silenceCount].X := silenceStart / FSampleRate;
      Result[silenceCount].Y := Length(envelope) / FSampleRate;
    end;
  finally
    FThreshold := oldThreshold;
  end;
end;

function TAudioAnalyzer.GetAmplitudeEnvelope(buffer: TAudioBuffer; windowSize: Integer): TDoubleArray;
var
  I, windowCount, startIdx, endIdx: Integer;
begin
  if windowSize < 1 then windowSize := FWindowSize;

  windowCount := buffer.SampleCount div windowSize;
  if buffer.SampleCount mod windowSize > 0 then
    Inc(windowCount);

  SetLength(Result, windowCount);

  for I := 0 to windowCount - 1 do
  begin
    startIdx := I * windowSize;
    endIdx := Min((I + 1) * windowSize - 1, buffer.SampleCount - 1);
    Result[I] := buffer.GetRMS(startIdx, endIdx);
  end;
end;

{ Utility functions }

function MouthStateToString(state: TMouthState): string;
begin
  case state of
    msClosed: Result := 'Closed';
    msSmallOpen: Result := 'SmallOpen';
    msMediumOpen: Result := 'MediumOpen';
    msWideOpen: Result := 'WideOpen';
  else
    Result := 'Unknown';
  end;
end;

function StringToMouthState(const str: string): TMouthState;
var
  lowerStr: string;
begin
  lowerStr := LowerCase(str);
  if lowerStr = 'closed' then
    Result := msClosed
  else if lowerStr = 'smallopen' then
    Result := msSmallOpen
  else if lowerStr = 'mediumopen' then
    Result := msMediumOpen
  else if lowerStr = 'wideopen' then
    Result := msWideOpen
  else
    Result := msClosed;
end;

function MouthStateToIndex(state: TMouthState): Integer;
begin
  Result := Ord(state);
end;

function IndexToMouthState(index: Integer): TMouthState;
begin
  if (index >= Ord(Low(TMouthState))) and (index <= Ord(High(TMouthState))) then
    Result := TMouthState(index)
  else
    Result := msClosed;
end;

end.
