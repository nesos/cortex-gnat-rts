--  Copyright (C) 2016 Free Software Foundation, Inc.
--
--  This file is part of the Cortex GNAT RTS project. This file is
--  free software; you can redistribute it and/or modify it under
--  terms of the GNU General Public License as published by the Free
--  Software Foundation; either version 3, or (at your option) any
--  later version. This file is distributed in the hope that it will
--  be useful, but WITHOUT ANY WARRANTY; without even the implied
--  warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
--
--  As a special exception under Section 7 of GPL version 3, you are
--  granted additional permissions described in the GCC Runtime
--  Library Exception, version 3.1, as published by the Free Software
--  Foundation.
--
--  You should have received a copy of the GNU General Public License
--  and a copy of the GCC Runtime Library Exception along with this
--  program; see the files COPYING3 and COPYING.RUNTIME respectively.
--  If not, see <http://www.gnu.org/licenses/>.

with STM32_SVD.FLASH; use STM32_SVD.FLASH;
with STM32_SVD.PWR;   use STM32_SVD.PWR;
with STM32_SVD.RCC;   use STM32_SVD.RCC;
with HAL; use HAL;

separate (Startup)
procedure Set_Up_Clock is
begin
   --  Enable PWR clock
   declare
      APB1ENR : APB1ENR_Register;
   begin
      APB1ENR := RCC_Periph.APB1ENR;
      APB1ENR.PWREN := True;
      RCC_Periph.APB1ENR := APB1ENR;
   end;

   --  Set highest voltage for maximum frequency (168 MHz).
   --  DocID022152 Rev 6 Table 14.
   --  Postpone wait-until-ready until PLL is in use.
   declare
      CR  : STM32_SVD.PWR.CR_Register;
   begin
      CR := PWR_Periph.CR;
      CR.VOS := 3;
      PWR_Periph.CR := CR;
   end;

   --  Setup internal high-speed clock and wait for stabilisation.
   declare
      CR : STM32_SVD.RCC.CR_Register;
   begin
      CR := RCC_Periph.CR;
      CR.HSION := True;
      RCC_Periph.CR := CR;
      loop
         CR := RCC_Periph.CR;
         exit when CR.HSIRDY = True;
      end loop;
   end;

   --  Setup external high-speed clock and wait for stabilisation.
   declare
      CR : STM32_SVD.RCC.CR_Register;
   begin
      CR := RCC_Periph.CR;
      CR.HSEON := True;
      --  Don't set HSEBYP (i.e. don't bypass external oscillator)
      RCC_Periph.CR := CR;
      loop
         CR := RCC_Periph.CR;
         exit when CR.HSERDY = True;
      end loop;
   end;

   --  Setup internal low-speed clock and wait for stabilisation.
   declare
      CSR : STM32_SVD.RCC.CSR_Register;
   begin
      CSR := RCC_Periph.CSR;
      CSR.LSION := True;
      RCC_Periph.CSR := CSR;
      loop
         CSR := RCC_Periph.CSR;
         exit when CSR.LSIRDY = True;
      end loop;
   end;

   --  Activate the PLL at 96 MHz
   declare
      CR : STM32_SVD.RCC.CR_Register;
   begin
      RCC_Periph.PLLCFGR := (PLLM   => 8,
                             PLLN   => 384,
                             PLLP   => 1,   -- 384/4 = 96 Main CPU Clock
                             PLLSRC => True,   -- HSE
                             PLLQ   => 8,
                             others => <>);
      CR := RCC_Periph.CR;
      CR.PLLON := True;
      RCC_Periph.CR := CR;
      loop
         CR := RCC_Periph.CR;
         exit when CR.PLLRDY = True;
      end loop;
   end;
   --  Wait until voltage supply scaling is ready (must be after PLL
   --  is ready).
   declare
      CSR : STM32_SVD.PWR.CSR_Register;
   begin
      loop
         CSR := PWR_Periph.CSR;
         exit when CSR.VOSRDY = True;
      end loop;
   end;

   --  Set flash latency to 5 wait states _before_ increasing the clock.
   declare
      ACR : STM32_SVD.FLASH.ACR_Register;
   begin
      FLASH_Periph.ACR := (LATENCY => 5,
                           PRFTEN  => True,
                           ICEN    => True,
                           DCEN    => True,
                           others  => <>);
      --  Not sure we need to check this.
      loop
         ACR := FLASH_Periph.ACR;
         exit when ACR.LATENCY = 5;
      end loop;
   end;

   --  Configure clocks.
   RCC_Periph.CFGR :=
     (SW      => 2,            -- clock source is PLL
      HPRE    => 0,            -- AHB prescale = 1
      PPRE    => (As_Array => True,
                  Arr => (5,   -- APB lo speed prescale (PPRE1) = 4
                          4)), -- APB hi speed prescale (PPRE2) = 2
      MCO1    => 0,            -- MCU clock output 1 HSI selected
      MCO1PRE => 0,            -- MCU clock output 1 prescale = 1
      MCO2    => 0,            -- MCU clock output 2 SYSCLK selected
      MCO2PRE => 7,            -- MCU clock output 2 prescale = 5
      others  => <>);
   declare
      CFGR : STM32_SVD.RCC.CFGR_Register;
   begin
      loop
         CFGR := RCC_Periph.CFGR;
         exit when CFGR.SWS = 2; -- PLL running
      end loop;
   end;

end Set_Up_Clock;
