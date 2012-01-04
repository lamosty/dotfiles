-- Imports {{{
import XMonad
import qualified XMonad.StackSet as W

import XMonad.Hooks.DynamicLog
import XMonad.Hooks.FadeInactive

import XMonad.Layout.NoBorders
import XMonad.Layout.Maximize
import XMonad.Layout.PerWorkspace
import XMonad.Layout.IM
import XMonad.Layout.Grid
import XMonad.Layout.IndependentScreens
import XMonad.Layout.Master

import XMonad.Util.Run
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.UrgencyHook

import XMonad.Actions.NoBorders
import XMonad.Actions.CycleWS
import XMonad.Actions.TopicSpace
import XMonad.Actions.SpawnOn

import XMonad.Prompt
import XMonad.Prompt.Shell
import XMonad.Prompt.Ssh
import XMonad.Prompt.Window
import XMonad.Prompt.Workspace
import XMonad.Prompt.AppendFile

import Data.Ratio
import qualified Data.Map as M
-- }}} 

-- Main {{{ 
main = do 
  nScreens <- countScreens
  din <- mapM (spawnPipe . xmobarCommand) [0 .. nScreens-1]
  sp <- mkSpawner
  xmonad $ withUrgencyHook NoUrgencyHook
         $ defaultConfig
              { workspaces         = ["1:init", "2:web", "3:term", "4:chat", "5:db", "6:dev", "7:mail", "8:media", "9:office"]
              , terminal           = "urxvtc"
              , modMask            = mod4Mask
              , manageHook         = myManageHook sp
              , keys               = \c -> myKeys sp `M.union`
                                          keys defaultConfig c
              , logHook            = myLogHook din nScreens
              , layoutHook         = myLayoutHook
              }
-- }}}

-- Log Hook {{{
myLogHook din nScreens = do
    mapM_ dynamicLogWithPP $ zipWith pp din [0..nScreens]
    fadeInactiveLogHook 0.9
-- }}}

-- Layout Hook {{{
myLayoutHook = onWorkspace "4:chat" (avoidStruts $ withIM (1%5) (Role "buddy_list") (smartBorders $ avoidStruts $ Grid)) $
               onWorkspace "5:db" (avoidStruts $ mastered (1/100) (5/6) $ Grid ||| Full) $
               smartBorders (avoidStruts $ tiled ||| Mirror tiled ||| noBorders Full)
      where
        tiled = maximize (Tall 1 (3%100) (1%2))
-- }}}
 
-- Manage Hook {{{
myManageHook sp = manageSpawn sp
                <+>
                composeOne [
                  isFullscreen -?> doFullFloat
                ]
                <+> composeAll [
                      className =? "MPlayer" --> doFloat,
                      className =? "Volwheel" --> doFloat,
                      className =? "Eclipse" --> doFloat,
                      className =? "Shiretoko" --> doF (W.shift "2:web"),
                      className =? "Firefox" --> doF (W.shift "2:web"),
                      className =? "Navigator" --> doF (W.shift "2:web"),
                      className =? "Pidgin" --> doF (W.shift "4:chat"),
                      className =? "Eclipse" --> doF (W.shift "6:dev"),
                      className =? "eclipse" --> doF (W.shift "6:dev"),
                      className =? "Shredder" --> doF (W.shift "7:mail"),
                      title     =? "File Operation Progress" --> doFloat
                ]
                <+> manageDocks
-- }}}

-- Xmobar {{{

pp xmobar s = xmobarPP {
                     ppOutput = hPutStrLn xmobar
                   , ppTitle = case s of
                                0 -> xmobarColor "white" "" . shorten 110
                                _ -> xmobarColor "black" "" . shorten 110
                   , ppCurrent = xmobarColor "white" "black" . pad
                   , ppHidden = pad
                   , ppSep = xmobarColor "#555" "" " / "
                   , ppWsSep = ""
                   , ppUrgent = color "red"
                   }
                  where color c = xmobarColor c ""

xmobarCommand (S s) = unwords ["xmobar", "-x", show s, "-t", template s, "-c", "'[Run StdinReader, Run Network \"eth0\" [] 10, Run Memory [] 10, Run MultiCpu [\"-t\", \"Cpu: <total0>/<total1>\"] 10, Run CoreTemp [\"-t\", \"<core0>°C/<core1>°C\"] 10, Run CpuFreq [\"-t\", \"<cpu0>GHz/<cpu1>GHz\"] 10, Run Battery [\"-t\", \"Batt: <leftbar>(<left>%)\"] 10]'"] where
    template 0 = "%StdinReader%}{%date%"
    template _ = "'%StdinReader%}{%multicpu% * %cpufreq% * %coretemp% | %memory% | %eth0% | %battery%'"


-- }}}

-- Keys {{{
myKeys sp = M.fromList $
  [
    ((mod4Mask, xK_m), withFocused (sendMessage . maximizeRestore)),
    ((mod4Mask, xK_b), withFocused toggleBorder),
    ((mod4Mask, xK_p), shellPromptHere sp myXPConfig),
    ((mod4Mask, xK_s), sshPrompt myXPConfig),
    ((mod4Mask, xK_i), appendFilePrompt myXPConfig "/home/kremso/gtd-inbox"),
    ((mod4Mask, xK_Escape), toggleWS),
    ((mod4Mask, xK_o     ), swapNextScreen),
    ((mod4Mask .|. shiftMask, xK_l     ), nextScreen),
    ((mod4Mask .|. shiftMask, xK_h     ), prevScreen),
    ((mod4Mask, xK_x     ), spawnHere sp "thunar"),
    ((shiftMask .|. controlMask, xK_l     ), spawn "xscreensaver-command -activate")

 
  ]
--}}}

-- Shell Prompt Config {{{
myXPConfig = defaultXPConfig {
  font                = "-*-profont-*-*-*-*-13-*-*-*-*-*-iso8859-*",
  promptBorderWidth = 0,
  bgColor           = "#111111",
  fgColor           = "#d5d3a7",
  bgHLight          = "#aecf96",
  fgHLight          = "black"
}
-- }}}
