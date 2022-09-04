unit Unit1; 

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, MyWidgetSet, LResources;

type

  { TMyForm1 }

  TMyForm1 = class(TMyForm)
    Button1: TButton;
    Button2: TButton;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  MyForm1: TMyForm1;

implementation

{$R unit1.lfm}

end.

