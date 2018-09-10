--  Copyright (C) 2016, 2017 Free Software Foundation, Inc.

--  This file is part of the Cortex GNAT RTS package.
--
--  The Cortex GNAT RTS package is free software; you can redistribute
--  it and/or modify it under the terms of the GNU General Public
--  License as published by the Free Software Foundation; either
--  version 3 of the License, or (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
--  General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program; see the file COPYING3.  If not, see
--  <http://www.gnu.org/licenses/>.

with Ada.Real_Time;
with STM32_SVD.GPIO; use STM32_SVD.GPIO;
with STM32_SVD.RCC;  use STM32_SVD.RCC;

package body Heartbeat is

   task Beat
   with Storage_Size => 1024
   is
      pragma Task_Name ("heartbeat.beat");
   end Beat;

   task body Beat is
      use type Ada.Real_Time.Time;
   begin
      for J in 1 .. 5 loop
         GPIOA_Periph.BSRR.BS := (As_Array => True,
                                  Arr => (5 => True, others => False));
         delay until Ada.Real_Time.Clock + Ada.Real_Time.Milliseconds (100);
         GPIOA_Periph.BSRR.BR := (As_Array => True,
                                  Arr => (5 => True, others => False));
         delay until Ada.Real_Time.Clock + Ada.Real_Time.Milliseconds (100);
      end loop;
      loop
         declare
            Set   : BSRR_BS_Field_Array;
            Reset : BSRR_BR_Field_Array;
         begin
               Set := (others => False);
               Set (5) := True;
               GPIOA_Periph.BSRR.BS := (As_Array => True,
                                        Arr => Set);
               delay until
                 Ada.Real_Time.Clock + Ada.Real_Time.Milliseconds (100);
               Reset := (others => False);
               Reset (5) := True;
               GPIOA_Periph.BSRR.BR := (As_Array => True,
                                        Arr => Reset);
               delay until
                 Ada.Real_Time.Clock + Ada.Real_Time.Milliseconds (100);
         end;
      end loop;
   end Beat;

begin
   --  Enable GPIOD
   declare
      AHB1ENR : STM32_SVD.RCC.AHB1ENR_Register;
   begin
      AHB1ENR := RCC_Periph.AHB1ENR;
      AHB1ENR.GPIOAEN := True;
      RCC_Periph.AHB1ENR := AHB1ENR;
   end;

   GPIOA_Periph.MODER := (As_Array => True,
                          Arr      => (5 => 1,
                                       others   => 0));
end Heartbeat;
