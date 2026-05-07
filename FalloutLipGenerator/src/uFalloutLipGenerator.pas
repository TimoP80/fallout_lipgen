(*
  Fallout Lip Generator - Main Library Unit
  
  This unit exports all public interfaces for the lip generation library.
  
  Copyright (c) 2026
  License: MIT
*)

unit uFalloutLipGenerator;

{$mode objfpc}{$H+}

interface

uses
  uAudioBuffer, uWavReader, uSignalAnalysis, uFalloutLipFormat, uLipGenerator;

// Type exports
export type
  TAudioBuffer = uAudioBuffer.TAudioBuffer;
  TWavReader = uWavReader.TWavReader;
  TEnvelopeDetector = uSignalAnalysis.TEnvelopeDetector;
  TAudioAnalyzer = uSignalAnalysis.TAudioAnalyzer;
  TMouthState = uSignalAnalysis.TMouthState;
  TLipFrame = uSignalAnalysis.TLipFrame;
  TLipFrameArray = uSignalAnalysis.TLipFrameArray;
  TFalloutLipFile = uFalloutLipFormat.TFalloutLipFile;
  TFalloutLipSerializer = uFalloutLipFormat.TFalloutLipSerializer;
  TLipFileReader = uFalloutLipFormat.TLipFileReader;
  TLipGenerator = uLipGenerator.TLipGenerator;
  TLipGenOptions = uLipGenerator.TLipGenOptions;
  TLipGenResult = uLipGenerator.TLipGenResult;
  TProgressCallback = uLipGenerator.TProgressCallback;

// Function exports
export function DefaultLipGenOptions: TLipGenOptions;
export function MouthStateToString(state: TMouthState): string;
export function StringToMouthState(const str: string): TMouthState;
export function MouthStateToIndex(state: TMouthState): Integer;
export function IndexToMouthState(index: Integer): TMouthState;

// Constants
export const
  LIP_SIGNATURE: array[0..3] of AnsiChar = ('L', 'I', 'P', #0);
  LIP_FPS_10 = 10;
  LIP_FPS_12 = 12;
  LIP_FPS_15 = 15;
  LIP_MOUTH_CLOSED = 0;
  LIP_MOUTH_SMALL_OPEN = 1;
  LIP_MOUTH_MEDIUM_OPEN = 2;
  LIP_MOUTH_WIDE_OPEN = 3;
  MAX_LIP_FRAMES = 10000;

implementation

uses
  uSignalAnalysis, uLipGenerator;

function DefaultLipGenOptions: TLipGenOptions;
begin
  Result := uLipGenerator.DefaultLipGenOptions;
end;

function MouthStateToString(state: TMouthState): string;
begin
  Result := uSignalAnalysis.MouthStateToString(state);
end;

function StringToMouthState(const str: string): TMouthState;
begin
  Result := uSignalAnalysis.StringToMouthState(str);
end;

function MouthStateToIndex(state: TMouthState): Integer;
begin
  Result := uSignalAnalysis.MouthStateToIndex(state);
end;

function IndexToMouthState(index: Integer): TMouthState;
begin
  Result := uSignalAnalysis.IndexToMouthState(index);
end;

end.