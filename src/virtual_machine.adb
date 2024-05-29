with Ada.Strings.Unbounded.Text_IO; use Ada.Strings.Unbounded.Text_IO;
with Ada.Strings.Unbounded;         use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;             use Ada.Strings.Fixed;
with Ada.Strings.Maps;              use Ada.Strings.Maps;
with Ada.Directories;               use Ada.Directories;
with Ada.Real_Time;                 use Ada.Real_Time;
with Ada.Text_IO;                   use Ada.Text_IO;
with Ada.Strings;                   use Ada.Strings;
with GNAT.OS_Lib;                   use GNAT.OS_Lib;
with GNAT.String_Split;             use GNAT;
with Ada.Exceptions;                use Ada.Exceptions;

package body Virtual_Machine is

    --Read the exported data in PowerJoular format
    function Read_File_PowerJoular_Format
       (File_Path : String) return Float
    is
        F     : File_Type;
        Line  : Unbounded_String;
        Last  : Unbounded_String := To_Unbounded_String ("");
        Subs  : String_Split.Slice_Set;
        Seps  : constant String  := ",";
        Value : Float;
    begin
        -- Opens the file in read mode
        Open (F, In_File, File_Path);

        -- Read all lines to the end of the file to get the last one
        while not End_Of_File (F) loop
            Line := Get_Line (F);
            if Line /= To_Unbounded_String ("") then
                Last := Line;
            end if;
        end loop;

        -- Closing the file after playback
        Close (F);

        -- Processes the last line obtained
        String_Split.Create
           (S          => Subs,
            From       =>
               To_String
                  (Last),
            Separators => Seps,
            Mode       => String_Split.Multiple);

        -- Converts the value of the third column into a float
        Value := Float'Value (String_Split.Slice (Subs, 3));

        return Value;
    exception
        when others =>
            Ada.Text_IO.Put_Line
               ("The file cannot be found, check the path");
            OS_Exit (0);
    end Read_File_PowerJoular_Format;

   function Read_SingleLine_Format
      (File_Path : String) return Float
   is
       F      : File_Type;
       Line   : Unbounded_String;
       Result : Float := 0.0;
   begin
       Open (F, In_File, File_Path);
       Line := To_Unbounded_String (Get_Line (F));
       Close (F);

       -- Clean the string and keep only numbers and dots
       declare
           Temp  : String                    := To_String (Line);
           Clean : String (1 .. Temp'Length) := (others => '0');
           j     : Natural                   := 1;
       begin
           for i in Temp'Range loop
               if ('0' <= Temp (i) and Temp (i) <= '9') or Temp (i) = '.'
               then
                   Clean (j) := Temp (i);
                   j         := j + 1;
               end if;
           end loop;
           Line := To_Unbounded_String (Clean (1 .. j - 1));
       end;

       -- Attempted conversion
       begin
           Result := Float'Value (To_String (Line));
       exception
           when E : others =>
               Put_Line
                  ("Failed to convert to float: " & Exception_Message (E));
               OS_Exit (0);
       end;

       return Result;
   exception
       when E : others =>
           Put_Line ("Error after reading line: " & Exception_Message (E));
           OS_Exit (0);
   end Read_SingleLine_Format;

    function Calculate_VM_Consumption (File_Name : Unbounded_String; Power_Format : Unbounded_String) return Float is
        VM_File_Name    : String := To_String(File_Name);
        VM_Power_Format : String := To_String(Power_Format);
        Power           : Float;

        -- Customized exceptions
        Invalid_File_Name_Exception : exception;
        Invalid_Format_Exception    : exception;

    begin
        -- Check if file name parameter exist
        if (VM_File_Name) = "" then
            raise Invalid_File_Name_Exception;
        end if;

        -- Check file existence
        if not Exists ((VM_File_Name)) then
            raise Invalid_File_Name_Exception;
        end if;

        -- Iteration on supported formats
        if VM_Power_Format = ("powerjoular") then
            Power := Read_File_PowerJoular_Format (VM_File_Name);
        elsif VM_Power_Format = ("singleline") then
            Power := Read_SingleLine_Format (VM_File_Name);
        else
            raise Invalid_Format_Exception; -- Format not supported
        end if;

        return Power;

    exception
        when Invalid_File_Name_Exception =>
            Ada.Text_IO.Put_Line ("Error: The file name is invalid..");
            OS_Exit (0);
        when Invalid_Format_Exception    =>
            Ada.Text_IO.Put_Line
               ("Error: The specified power format is not supported.");
            OS_Exit (0);
    end Calculate_VM_Consumption;

end Virtual_Machine;