import XMonad

import XMonad.Layout.NoBorders
import XMonad.Layout.PerWorkspace
import XMonad.Layout.ResizableTile
import XMonad.Layout.Named
import XMonad.Layout.GridVariants
import XMonad.Layout.ThreeColumns
import XMonad.Layout.Maximize
import XMonad.Layout.WorkspaceDir

import XMonad.Actions.SpawnOn
import XMonad.Actions.Search
import XMonad.Actions.DynamicWorkspaces
import XMonad.Actions.CopyWindow(copy)
import XMonad.Actions.Submap

import XMonad.Hooks.UrgencyHook
import XMonad.Hooks.ManageDocks hiding (L)
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageHelpers

import XMonad.Util.NamedWindows
import XMonad.Util.Run(spawnPipe, hPutStrLn)
import XMonad.Util.EZConfig(additionalKeys, additionalKeysP)
import XMonad.Util.Run

import qualified XMonad.StackSet as W

import XMonad.Prompt
import XMonad.Prompt.Shell

import System.Exit
import System.IO
import System.Environment
import System.FilePath.Posix
import System.FilePath.Find

import Control.Monad(liftM2)

import Data.Monoid
import qualified Data.Map        as M

main = do
    myXmobar <- spawnPipe "xmobar"
    xmonad $ withUrgencyHookC NoUrgencyHook urgentConfig 
        $ conf myXmobar
        `additionalKeysP` myKeys
        `additionalKeysP` searchKeys 
        `additionalKeys`  myMMKeys

conf myConfig = defaultConfig {
        modMask             = mod4Mask,
        terminal            = "urxvt", 
        focusFollowsMouse   = False,
        workspaces          = myWorkspaces,
        borderWidth         = 2,
        normalBorderColor   = base03,
        focusedBorderColor  = base3,
        logHook             = dynamicLogWithPP $ xmobarPP
                    { ppOutput      = hPutStrLn myConfig 
                    , ppCurrent     = xmobarColor base3 "" . wrap "[" "]" 
                    , ppVisible     = xmobarColor base3 "" . wrap "(" ")"
                    , ppTitle       = xmobarColor base3 "" . shorten 50 
                    , ppSep         = "  »  "
                    , ppWsSep       = " "
                    , ppHidden      = xmobarColor base01 ""
                    , ppUrgent      = xmobarColor base3 yellow . pad
                    },
        layoutHook         = myLayout,
        manageHook         = myManageHook,
        startupHook        = myStartupHook
        }

myWorkspaces    = [" α ", " β ", " γ ", "comm", "music", "www", " π ", " ξ "] 

-- Keymappings
myKeys =    [ ("M-q",   spawn "killall xmobar && xmonad --recompile && xmonad --restart") 
            , ("M-a",   sendMessage MirrorShrink)
            , ("M-z",   sendMessage MirrorExpand) 
            , ("M-#",   withFocused (sendMessage . maximizeRestore))
            , ("M-d",   changeDir promptConfig)
            , ("M-p",   passPrompt promptConfig)
            , ("M-c",   shellPrompt promptConfig)
            ]

myMMKeys =  [ ((0, 0x1008FF12), spawn "amixer set Master toggle")
            , ((0, 0x1008FF11), spawn "amixer set Master 3%-")
            , ((0, 0x1008FF13), spawn "amixer set Master 3%+")
            , ((0, 0x1008FFB2), spawn "ncmpcpp toggle")
            , ((0, 0x1008FF02), spawn "xbacklight -inc 3")
            , ((0, 0x1008FF03), spawn "xbacklight -dec 3")
            , ((0, 0x1008FF59), spawn "ncmpcpp prev")
            , ((0, 0x1008FF95), spawn "ncmpcpp next")
            ]

searchKeys = [("M-o " ++ k, promptSearch promptConfig f  >> windows (W.view "www")) | (k,f) <- searchEngines ]
             ++ [("M-i " ++ k, selectSearch f >> windows (W.view "www")) | (k,f) <- searchEngines ]

searchEngines = [ ("g", google)
                , ("w", wikipedia) 
                , ("d", (searchEngine "dict" "http://www.dict.cc/?s=")) 
                , ("y", youtube) 
                , ("m", (searchEngine "discogs" "http://www.discogs.com/search/?q="))
                ]  

-- Hooks
myStartupHook = do
    spawnOn " α "   "urxvt -e ./.agents.sh"
    spawnOn "comm"  "urxvt -e mutt"
--  spawnOn "music" "urxvt -e ncmpcpp"
    spawnOn "www"   "iceweasel"

myManageHook = manageSpawn
               <+> composeAll
                   [ className =? "Evince"                         --> viewShift " π "
                   , className =? "Plugin-container"               --> doFloat         -- Flash fullscreen
                   , className =? "MATLAB"                         --> doFloat
                   , className =? "com-mathworks-util-PostVMInit"  --> doFloat         -- MATLAB plots
                   , className =? "Xmessage"                       --> doCenterFloat
                   , isDialog                                      --> doCenterFloat
                   ]
               <+> manageHook defaultConfig
               where   viewShift = doF . liftM2 (.) W.greedyView W.shift

myLayout =  avoidStruts $ 
            lessBorders Screen $
            workspaceDir "/home/andi" $
            onWorkspaces ["comm", "music", "www"] myResTall $
            allLayouts
            where   allLayouts = myResTall
                                 ||| myThreeCol
--                               ||| myGrid
--                               ||| myFull
                    myResTall = named "<fc=#fdf6e3>[</fc><fc=#839496> |-</fc><fc=#fdf6e3>]</fc>" 
                                $ maximize $ ResizableTall nmaster delta ratio []
                                where   nmaster = 1 
                                        ratio   = 1/2           -- golden ratio: toRational (2/(1+sqrt(5)::Double))
                                        delta   = 3/100
                    myThreeCol = named "<fc=#fdf6e3>[</fc><fc=#839496> ||</fc><fc=#fdf6e3>]</fc>" 
                                 $ maximize $ ThreeCol 1 (3/100) (1/2)
                    myFull = named "<fc=#fdf6e3>[</fc><fc=#839496>   </fc><fc=#fdf6e3>]</fc>" 
                             $ noBorders Full
                    myGrid = named  "<fc=#fdf6e3>[</fc><fc=#839496>-|-</fc><fc=#fdf6e3>]</fc>"
                             $ maximize $ SplitGrid L 2 3 (3/4) (16/10) (5/100)
                    
urgentConfig = UrgencyConfig 
    { suppressWhen = Focused
    , remindWhen = Dont 
    }

-- Prompt config
promptConfig = defaultXPConfig
    { font          = "xft:Ubuntu Mono"
    , fgColor       = base00
    , bgColor       = base3 
    , fgHLight      = base3 
    , bgHLight      = base1
    , borderColor   = base1
    , height        = 18 
    , position      = Bottom 
    }  

-- Password retrieval
data Pass = Pass
instance XPrompt Pass where
    showXPrompt Pass        = "Pass: "
    commandToComplete _ c   = c 
    nextCompletion _        = getNextCompletion

passPrompt :: XPConfig -> X ()
passPrompt c = do
    li <- io getPasswords
    mkXPrompt Pass c (mkComplFunFromList li) selectPassword

selectPassword :: String -> X ()
selectPassword s = spawn $ "pass -c " ++ s

getPasswords :: IO [String]
getPasswords = do
    home <- getEnv "HOME"
    let passwordStore = home </> ".password-store"
    entries <- find System.FilePath.Find.always (fileName ~~? "*.gpg") $ passwordStore
    return $ map ((makeRelative passwordStore) . dropExtension) entries
        
-- Colors (Solarized theme)
base03  = "#002b36"
base02  = "#073642"
base01  = "#586e75"
base00  = "#657b83"
base0   = "#839496"
base1   = "#93a1a1"
base2   = "#eee8d5"
base3   = "#fdf6e3"
yellow  = "#b58900"
orange  = "#cb4b16"
red     = "#dc322f"
magenta = "#d33682"
violet  = "#6c71c4"
blue    = "#268bd2"
cyan    = "#2aa198"
green   = "#859900"

--myDmenu = "dmenu_run -nf '\x23\&dcdccc' -sb '\x23\&dcdccc' -sf '\x23\&3f3f3f' -nb '\x23\&000000' -fn 'Inconsolata-12'"
