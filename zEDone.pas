(************************************************
* zEDone Virtual Computer V1.1 DEV              *
* copyright (c) 2012,2017 by ir. Marc Dendooven *
* zEDone is a virtual CP/M machine              *
* using my Z80 emulator (zED80)                 *
* (zED80 is still under construction)           *
* **********************************************)


program zEDone;

uses zED80, crt, math, sysUtils;

const	NrDr = 4;// number of drives 
		// if NrDr is changed, DriveNames should be added/removed and the BIOS should be adapted. 
	DriveName: array[0..NrDr-1] of string = ('driveA','driveB','driveC','driveD');

var 
	    mem: array[0..$FFFF]of byte; //64K ram
	    buf: array [0..127] of byte; //128 Byte buffer for disk drives
	    drive: array[0..NrDr-1] of file; //disk drives
	    driveNr: 0..NrDr-1; //current drive
	    track: 0..76; //current track
	    sector: 1..26; //current sector
	    DMA: 0..$FFFF; //DMA address in mem.

	    c: char;
	    filename: string;
	    i: cardinal;

		
procedure exit;
begin
	Writeln;
	writeln('goodbye ! ');
	for i:=0 to NrDr-1 do close(drive[i]);
	Halt
end;

procedure load_prg (filename: string; address: word);
var     f : file of byte;
        b : byte;
        i : cardinal = 0;
        a : cardinal; 
begin
        a := address;
        {$i-}
        assign (f,filename);
        reset(f);
        {$i+}
        if ioresult <> 0
        then
                writeLn('No file named '+filename)
        else
           begin
                while not eof(f) do
                    begin
                        read(f,b);
                        mem[address] := b;
                        inc(address);
                        inc(i)
                    end;
                close(f);
                writeln('program '+filename+' loaded. ',i,' bytes ',ceil(i/256),' pages from $',hexstr(a,4),' to $',hexstr(address-1,4))
           end;
end;

procedure addfile;
begin
	writeln;
	write('load an external file to the transient area ? (y/n)');
	readln(c);
	if c<>'n' then begin
						write('filename: ');
						readln(filename);
						load_prg(filename,$100);
						writeln;
						writeln('if succesfully loaded the external file can now be saved local with');
						writeln; 
						writeln('"SAVE <Nr of pages> [driveletter:]<file name>"');
						writeln 
				   end;
end;

procedure readData;
var i: cardinal;
begin
	Seek(drive[driveNr],track*26+Sector-1);
	BlockRead(drive[driveNr],buf,1);
	for i := 0 to 127 do mem[i+DMA] := buf[i]	
end;

procedure writeData;
var i: cardinal;
begin
	for i := 0 to 127 do buf[i] := mem[i+DMA];
	Seek(drive[driveNr],track*26+Sector-1);
	BlockWrite(drive[driveNr],buf,1)		
end;

procedure poke(Addr:word; Value:byte);
begin
	mem[Addr] := Value
end;

function peek(Addr:word): byte;
begin
	peek := mem[Addr]
end;

procedure output(Port:word; Value:byte);
begin
	case lo(port) of 
		0: begin
			if value = 0 then writeln ('*** debug ***') else write(chr(Value));
		   end; 
		$10: driveNr := Value;
		$11: track := Value;
		$12: sector := Value;
		$13: DMA := (DMA and $FF00) or Value; //set DMA lo 
		$14: DMA := (DMA and $00FF) or (Value << 8); //set DMA hi
		$15: if Value = 0 then readData else writeData
	end	
end;




function input(Port:word):byte;
var key: integer;
begin
	case lo(port) of
		0: if keypressed then begin 
			//input := ord(readkey);
			key := ord(readkey); //if key=13 then step:=true;
			if key = 0 then //not an ascii characters
					if ord(readkey) = 66 then key:=254; //exit; !!! DEBUG !
					//press F8 to exit
			input := key
		    end;	  
		1: begin sleep(1); if keypressed then input := $FF else input := 0 end;
		else input := 255
	end;
end;

procedure user;
begin
    writeln;writeln;writeln('WARM BOOT');load_prg('CPM22',$DC00);
end;	

begin
	writeln;
	writeln('***********************************************');
	writeln('* Welcome to zEDone emulator. V1.1 DEV        *');
	writeln('* (C)2012-2017 by ir. Marc Dendooven          *');
//	writeln('* consult READ.ME for more information        *'); 
	writeln('***********************************************');
	writeln;		
	writeln('push F8 on command line to exit');
	writeln;
	
	filemode := 2; //a reset should now open the file in r/w mode. (default ?)	
	for i := 0 to NrDr-1 do 
		begin
			assign(drive[i],driveName[i]); // a file named driveA..driveD should exist. 
			Reset(drive[i]) // blocksize default 128
		end;
	load_prg('CPM22',$DC00);
	load_prg('edBIOS',$F200);
	addFile;
	runZED80($F200, 0, @peek, @input, @poke, @output, @user)

end.
