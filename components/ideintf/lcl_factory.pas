{
  Temporary,
  This unit can only here (inside IDEIntf.lpk) to avoid circular reference.
  Perhap will be resolved someday, when 'RegisterComponentFactory'
  was declared inside Classes.pas (FCL.lpk?)
  --x2nie

  Unit Description: registering LCL root components.
}
unit lcl_factory;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, LCLClasses;

procedure Register;

implementation

uses ComponentEditors;

procedure Register;
begin
    RegisterComponentFactory('LCL', [TControl, TLCLComponent]);
end;

end.

