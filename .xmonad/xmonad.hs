import XMonad

import XMonad.Layout.NoBorders 
import XMonad.Layout.PerWorkspace
import XMonad.Layout.ResizableTile
import XMonad.Layout.Named
import XMonad.Layout.Maximize
import XMonad.Layout.WorkspaceDir

import XMonad.Actions.SpawnOn
import XMonad.Actions.Search
import XMonad.Actions.CycleWS (swapNextScreen)

import XMonad.Hooks.UrgencyHook
import XMonad.Hooks.ManageDocks hiding (L)
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageHelpers

import XMonad.Util.EZConfig(additionalKeys, additionalKeysP)
import XMonad.Util.Run
import XMonad.Util.Scratchpad

import qualified XMonad.StackSet as W

import XMonad.Prompt
import XMonad.Prompt.Shell

import System.Environment
import System.FilePath.Posix
import System.FilePath.Find

import Control.Monad(liftM2)


main = do
    myXmobar <- spawnPipe "xmobar -x 1"
    xmonad $ withUrgencyHookC NoUrgencyHook urgentConfig 
        $ conf myXmobar
        `additionalKeysP` myKeys
        `additionalKeysP` searchKeys 
        `additionalKeys`  myMMKeys

conf myConfig = defaultConfig {
        modMask             = mod4Mask,
        terminal            = myTerminal,
        focusFollowsMouse   = False,
        workspaces          = myWorkspaces,
        borderWidth         = 2,
        normalBorderColor   = dark0,
        focusedBorderColor  = light0,
        logHook             = dynamicLogWithPP xmobarPP
                    { ppOutput      = hPutStrLn myConfig
                    , ppCurrent     = xmobarColor light0 "" . wrap "[" "]" . hideNSP
                    , ppVisible     = xmobarColor light0 "" . wrap "(" ")" . hideNSP
                    , ppTitle       = xmobarColor light1 "" . shorten 90 
                    , ppSep         = "  »  "
                    , ppWsSep       = " "
                    , ppHidden      = xmobarColor light4 "" . hideNSP
                    , ppUrgent      = xmobarColor dark0 yellow
                    },
        layoutHook         = myLayout,
        manageHook         = myManageHook,
        startupHook        = myStartupHook
        }
        where
            hideNSP ws = if ws == "NSP" then "" else ws
myTerminal = "urxvt"
-- Keymappings
myKeys =    [ ("M-q",   spawn "killall xmobar && xmonad --recompile && xmonad --restart") 
            , ("M-a",   sendMessage MirrorShrink)
            , ("M-z",   sendMessage MirrorExpand) 
            , ("M-#",   withFocused (sendMessage . maximizeRestore))
            , ("M-d",   changeDir promptConfig >> spawn "./.resume.sh")
            , ("M-p",   passPrompt promptConfig)
            , ("M-c",   shellPrompt promptConfig)
            , ("M-r",   swapNextScreen)
            , ("M-s",   scratchpadSpawnActionTerminal myTerminal)
            ]
    
myMMKeys =  [ ((0, 0x1008FF12),     spawn "amixer set Master toggle")
            , ((0, 0x1008FF11),     spawn "amixer set Master 3%-")
            , ((0, 0x1008FF13),     spawn "amixer set Master 3%+")
            , ((0, 0x1008FFB2),     spawn "ncmpcpp toggle")
            , ((0, 0x1008FF02),     spawn "xbacklight -inc 3")
            , ((0, 0x1008FF03),     spawn "xbacklight -dec 3")
            , ((0, 0x1008FF59),     spawn "ncmpcpp prev")
            , ((0, 0x1008FF95),     spawn "ncmpcpp next")
            , ((mod4Mask, xK_Print), spawn "toggle-touchpad")
            ]

searchKeys = [("M-o" ++ k, promptSearch promptConfig f  >> windows (W.view " Ψ ")) | (k,f) <- searchEngines ]
             ++ [("M-i " ++ k, selectSearch f >> windows (W.view " Ψ ")) | (k,f) <- searchEngines ]

searchEngines = [ ("g", google)
                , ("w", wikipedia) 
                , ("d", (searchEngine "dict" "http://www.dict.cc/?s=")) 
                , ("y", youtube) 
                , ("m", (searchEngine "discogs" "http://www.discogs.com/search/?q="))
                ]  

-- Hooks
myStartupHook = do
    spawn           "random-wallpaper"
    spawnOn " α "   "urxvt -e ./.agents.sh"
    spawnOn " Ψ "   "iceweasel"
    spawnOn " Σ "   "urxvt -e mutt"
--  spawnOn " Θ "   "urxvt -e ncmpcpp"

myManageHook = scratchpadManageHook (W.RationalRect (1/6) (1/6) (4/6) (4/6)) 
               <+> manageSpawn
               <+> composeAll
                   [ className =? "Zathura"                        --> viewShift " π "
                   , className =? "Vlc"                            --> doFloat >> viewShift " Θ "
                   , className =? "Plugin-container"               --> doFloat         -- Flash fullscreen
                   , className =? "MATLAB"                         --> doFloat
                   , className =? "com-mathworks-util-PostVMInit"  --> doFloat         -- MATLAB plots
                   , className =? "Xmessage"                       --> doCenterFloat
                   , manageDocks
                   ]
               <+> manageHook defaultConfig
               where   viewShift = doF . liftM2 (.) W.greedyView W.shift

myWorkspaces    = [" α ", " β ", " γ ", " Ψ ", " Σ ", " π ", " Θ ", " ξ "] 

myLayout =  lessBorders Screen $
            workspaceDir "/home/andi" $
            onWorkspaces [" α ", " β ", " γ "] (myCodeLayout ||| myResTall) $
            onWorkspace  " Σ " (myCommLayout ||| myResTall) $
            onWorkspace  " π " (myPDFLayout ||| myResTall) $
            onWorkspace  " Θ " (myResTall ||| myVideoLayout) $
            myResTall 
            where   myResTall = named "<fc=#FDF4C1>[</fc><fc=#A89984> |-</fc><fc=#FDF4C1>]</fc>" 
                                $ avoidStruts $ maximize $ ResizableTall nmaster delta ratio []
                                where   nmaster = 1 
                                        ratio   = 1/2           -- golden ratio: toRational (2/(1+sqrt(5)::Double))
                                        delta   = 3/100
                    myPDFLayout = named "<fc=#FDF4C1>[</fc><fc=#A89984>  |</fc><fc=#FDF4C1>]</fc>"
                                  $ avoidStruts $  maximize $ ResizableTall nmaster delta ratio []
                                  where nmaster = 1
                                        ratio  = 4/5
                                        delta   = 3/100
                    myCodeLayout =  named "<fc=#FDF4C1>[</fc><fc=#A89984>-:-</fc><fc=#FDF4C1>]</fc>"
                                    $ avoidStruts $ maximize $ Mirror $ Tall 1 (3/100) (4/5)
                    myCommLayout =  named "<fc=#FDF4C1>[</fc><fc=#A89984>-:-</fc><fc=#FDF4C1>]</fc>"
                                    $ avoidStruts $ maximize $ Mirror $ Tall 1 (3/100) (2/3)  
                    myVideoLayout =  named "<fc=#FDF4C1>[</fc><fc=#A89984>   </fc><fc=#FDF4C1>]</fc>"
                                    $ noBorders Full


urgentConfig = UrgencyConfig 
    { suppressWhen = Focused
    , remindWhen = Dont 
    }

-- Prompt config
promptConfig = defaultXPConfig
    { font          = "xft:DejaVu Sans Mono:pixelsize=14"
    , fgColor       = dark2
    , bgColor       = light0
    , fgHLight      = light0 
    , bgHLight      = dark2 
    , borderColor   = light0 
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
        
-- Colors
{-
-- Solarized theme
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
-}

-- Gruvbox theme
dark0   = "#282828"
dark1   = "#3C3836"
dark2   = "#504945"
dark3   = "#665C54"
dark4   = "#7C6F64"
light0  = "#FDF4C1"
light1  = "#EBDBB2"
light2  = "#D5C4A1"
light3  = "#BDAE93"
light4  = "#A89984"
yellow  = "#FABD2F"
