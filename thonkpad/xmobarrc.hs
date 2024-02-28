Config { overrideRedirect = False
       , font = "xft:Inconsolata:pixelsize=20"
       , additionalFonts = []
       , bgColor = "black"
       , fgColor = "gray"
       , position = TopW L 90
       , commands = [ Run Weather "EFUT"
       			[ "--template", "<weather> <tempC>°C"
			, "-L","18","-H","25"
			, "--normal","green"
			, "--high","red"
			, "--low","lightblue"
			] 36000
                    , Run Cpu
		    	[ "-L","3"
			, "-H","50"
			, "--normal","green"
			, "--high","red"
			] 10
                    , Run Memory ["--template", "Mem: <usedratio>%"] 10
                    , Run Swap [] 10
                    , Run Date "%a %b %_d %Y %H:%M:%S" "date" 10
                    --, Run Network "eth0" ["-L","0","-H","32",
                    --                      "--normal","green","--high","red"] 10
                    --, Run Network "eth1" ["-L","0","-H","32",
                    --                      "--normal","green","--high","red"] 10
		    , Run XMonadLog
                    , Run Battery
                        [ "-t", "<acstatus>: <left>%"
                        , "--"
                        --, "-c", "charge_full"
                        , "-O", "AC"
                        , "-o", "Bat"
                        , "-h", "green"
                        , "-l", "red" 
                        ] 10
                    ]
       , sepChar = "%"
       , alignSep = "}{"
       , template = "%XMonadLog% }{ %battery% | %cpu% | %memory% * %swap% | <fc=#ee9a00>%date%</fc> | %EFUT% "
       , borderColor = "black"
       , border = TopB
       , alpha = 0
       , textOffset = -1
       , iconOffset = -1
       , lowerOnStart = True
       , pickBroadest = False
       , persistent = False
       , hideOnStart = False
       , iconRoot = "."
       , allDesktops = True
       , textOutputFormat = Ansi
       }
