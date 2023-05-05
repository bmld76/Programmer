
EnableExplicit  ;n'accepte que les variables déclarées
                ; Repeating power events:  wake at 7:45PM Monday
                ;Scheduled power events: [0]  wake at 04/16/2023 17:05:39 by 'com.apple.alarm.user-visible-com.apple.CalendarNotification.EKTravelEngine.periodicRefreshTimer' [1]  wake at 04/17/2023 12:23:58 by 'com.apple.alarm.user-visible-com.apple.acmd.alarm'
                ;https://frenchmac.com/astuces/comment-programmer-mac-pour-eteindre-allumer/

; sudo pmset Repeat wakeorpoweron MF 8:00:00 shutdown SU 23:30:00
; sudo pmset Repeat wakeorpoweron M 8:00:00
; sudo pmset Repeat shutdown F 23:32:10
; sudo pmset repeat cancel    pour tout effacer
; /usr/bin/pmset Repeat restart MTWRFSU 00:00:00

; PMSET doc
; pmset Repeat type weekdays time
; The various types documented in pmset’s man page are As follows:
; 
; sleep – puts the Mac To sleep
; wake – wakes the Mac from sleep
; poweron – starts up the Mac If the Mac is powered off
; shutdown – shuts down the Mac
; wakeorpoweron – depending on If the Mac is off Or asleep, the Mac will wake Or start up As needed
; restart

; The weekday options are As follows:
; 
; M = Monday
; T = Tuesday
; W = Wednesday
; R = Thursday
; F = Friday
; S = Saturday
; U = Sunday
; The time option documented in the man page is As follows:
; 
; HH:mm:ss
; The time must be set in 24 hour format, With a leading zero For numbers less than 10.

Global jour.s, heure.s , minute.s, hr, min, wake,shutdown,  commandetexte.s, jourwake.s , jourshut.s, hrshut, minshut, ampm.s, ampmshut.s
Global password.s, ok, sleep, restart,CommandeShutdown.s, flagShutdown
Global DossierParametre.s, ExistParametre, FichierParam.s

XIncludeFile "Apropos fr.pbf"      ; tamplate a propos (MAC)
XIncludeFile "Param fr.pbf"        ; tamplate a propos (MAC)


DossierParametre =  GetUserDirectory(#PB_Directory_ProgramData) +"pmset"
ExistParametre =   ExamineDirectory(#PB_Any, DossierParametre, "")  ; O si non existant 
If ExistParametre = 0 
  Debug "Pref 19 Creation du dossier config"
  If CreateDirectory(DossierParametre) = 0
    Debug "Pref 18 Creation repertoire config"
  EndIf
EndIf
FichierParam = DossierParametre+"/"+"Config"  ; simple fichier texte
Debug "param 24" + DossierParametre           ;

#version = "1.0"

Procedure SauvegardeConfig(param.s)
  Define mdp.s,i,a.w,b.w
  If CreateFile(0, FichierParam) 
    ;code le mot de passe
    For i = 1 To Len(param)
      a = Asc(Mid(param,i,1))
      b = a ! 128
      WriteWord(0, b)
    Next 
    CloseFile(0)
  EndIf
EndProcedure

Procedure.s LectureConfig()
  Define ident.s, val.s,b.w,c.w
  If ReadFile(0, FichierParam)     ; Si le fichier peut être lu , on continue...
    While Eof(0) = 0               ; lecture 2 par 2 : identifiant  puis valeur 
      b =  ReadWord(0)
      c = b ! 128
      password + Chr(c)   
    Wend
    CloseFile(0)               ; Ferme le fichier précédemment créé ou ouvert
    Debug " password "+password
    ProcedureReturn password
  Else
    ProcedureReturn ""
  EndIf 
EndProcedure


Procedure.s etat()
  
  Define commande, sortie.s
  commande = RunProgram("pmset", " -g sched", "", #PB_Program_Open|#PB_Program_Read)
  Sortie.s = ""
  If commande 
    
    While ProgramRunning(commande)
      If AvailableProgramOutput(commande)
        Sortie.s  + ReadProgramString(commande)
      EndIf
    Wend
    ; Sortie$ + "Code de retour : " + Str(ProgramExitCode(commande)) 
    CloseProgram(commande) ; Ferme la connexion vers le programme
  EndIf
  ;Debug Sortie$
  ProcedureReturn Sortie.s
  
EndProcedure

Procedure pmset(message.s,password.s)
  If CountProgramParameters()= 0
    Define ProgramID.i,ReadErr$, Exit,pw.s
    
    ProgramID = RunProgram("sudo",  message, "",#PB_Program_Open | #PB_Program_Read | #PB_Program_Write | #PB_Program_Error)
    
    While ProgramRunning(ProgramID)    
      Delay(200)    
      ReadErr$ = ReadProgramError(ProgramID)
      Debug ReadErr$
      
      If ReadErr$ ="Password:Sorry, try again."
        MessageRequester("", "Mot de passe erroné")
        exit = 0
      ElseIf ReadErr$ =""
        If exit = 1
          ok = 1
          Debug "sortie sur erreur"
          ;sortie sur erreur mot de passe
          Break
        EndIf
      Else  
        If exit = 1
          ok = 0
          Debug "sortie sur erreur"
          ;sortie sur erreur mot de passe
          Break
        EndIf
      EndIf
      If password = ""
        pw.s =InputRequester("Mot de passe", "Indiquer le mot de passe de la session", "" ,  #PB_InputRequester_Password)
        
        SauvegardeConfig(pw)
      Else
        pw.s = password
      EndIf   
      If ProgramRunning(ProgramID)
        WriteProgramStringN(ProgramID, pw)
        exit = 1
      EndIf
    Wend
    Debug "sortie mot de passe ok"
    ;End
  Else
    MessageRequester( "Hello", "Code correct")
  EndIf
  
  Debug "suite "+ ok
  
EndProcedure


Procedure LireEtat()
  
  Define retour.s, Resultat, max, horaire.s
  
  retour.s = etat()

  Resultat = FindString(retour , "Repeating power events" )
  Debug "Repeating power events >"+ resultat
  Debug "----------------------------------------------------"
  
  ; recherche si shutdown pour limiter la recherche des jouet et heure pour wakeonpower

  
  If FindString(retour , "shutdown" ) > 0
    max = FindString(retour , "shutdown" )
  ElseIf FindString(retour , "sleep" ) > 0
    max = FindString(retour , "sleep" )
  ElseIf FindString(retour , "restart" ) > 0
    max = FindString(retour , "restart" )
  Else
    max = Len(retour)
  EndIf
  

  
  Resultat = FindString(Left(retour,max) , "wakepoweron" )
  If resultat 
    wake = #True
    
    ;horaire
    horaire.s = Trim(Mid(retour,Resultat+Len("wakepoweron at "),7))
    ampm.s = Right(horaire, 2)
    horaire = Left(horaire,Len(horaire)-2) ; supprime am/pm
    hr = Val(Left(horaire, 2))
    min = Val(Right(horaire, 2))
    If ampm = "PM"
      hr = hr + 12
    EndIf
    
    Debug "parametre wake on :"
    Debug horaire.s
    Debug ampm
    Debug hr
    Debug min
    ;jour
    Debug "max >>>>>>>>>>>>> " + max

    
    If FindString(Left(retour,max) , "weekends" )
      jour = "Week-ends" 
    ElseIf FindString(Left(retour,max) , "weekdays" )
      jour = "Jours de la semaine" 
    ElseIf FindString(Left(retour,max) , "every day" )
      jour = "Tous les jours" 
    ElseIf FindString(Left(retour,max) , "Monday" )
      jour = "lundi"
    ElseIf FindString(Left(retour,max) , "Tuesday" )
      jour = "mardi"
    ElseIf FindString(Left(retour,max) , "Wednesday" )
      jour = "mercredi"
    ElseIf FindString(Left(retour,max) , "Thursday" )
      jour = "jeudi"
    ElseIf FindString(Left(retour,max) , "Friday" )
      jour = "vendredi"
    ElseIf FindString(Left(retour,max) , "Saturday" )
      jour = "samedi"
    ElseIf FindString(Left(retour,max) , "Sunday" )
      jour = "dimanche"
    EndIf
  Else
    wake = #False
  EndIf  
  
  
  ; shutdown
  Debug "Parametre shutdown : >>>>> "
  
  If FindString(retour , "shutdown" )
    resultat = FindString(retour , "shutdown" )
    CommandeShutdown = "shutdown"
    shutdown = #True
    flagShutdown = #True
  ElseIf FindString(retour , "sleep" )
    resultat = FindString(retour , "sleep" )
    CommandeShutdown = "sleep"
    sleep = #True
    flagShutdown = #True
  ElseIf FindString(retour , "restart" )
    resultat = FindString(retour , "restart" )
    CommandeShutdown = "restart"
    restart = #True
    flagShutdown = #True
  EndIf
  
  
  If flagShutdown 
    ;horaire
    If shutdown 
      horaire.s = Trim(Mid(retour,Resultat+Len("shutdown at "),7))
    EndIf
    If sleep
      horaire.s = Trim(Mid(retour,Resultat+Len("sleep at "),7))
    EndIf
    If restart
      horaire.s = Trim(Mid(retour,Resultat+Len("restart at "),7))
    EndIf
    
    ampm.s = Right(horaire, 2)
    horaire = Left(horaire,Len(horaire)-2) ; supprime am/pm
    hrshut = Val(Left(horaire, 2))
    minshut = Val(Right(horaire, 2))
    If ampmshut = "PM"
      hrshut = hrshut + 12
    EndIf
    
    Debug horaire.s
    Debug ampmshut
    Debug hrshut
    Debug minshut
    ;jour
    
    If FindString(Mid(retour,Resultat,Len(retour)) , "weekends" )
      jourshut = "Week-ends" 
    ElseIf FindString(Mid(retour,Resultat,Len(retour)) , "weekdays" )
      jourshut = "Jours de la semaine" 
    ElseIf FindString(Mid(retour,Resultat,Len(retour)) , "every day" )
      jourshut = "Tous les jours" 
    ElseIf FindString(Mid(retour,Resultat,Len(retour)) , "Monday" )
      jourshut = "lundi"
    ElseIf FindString(Mid(retour,Resultat,Len(retour)) , "Tuesday" )
      jourshut = "mardi"
    ElseIf FindString(Mid(retour,Resultat,Len(retour)) , "Wednesday" )
      jourshut = "mercredi"
    ElseIf FindString(Mid(retour,Resultat,Len(retour)) , "Thursday" )
      jourshut = "jeudi"
    ElseIf FindString(Mid(retour,Resultat,Len(retour)) , "Friday" )
      jourshut = "vendredi"
    ElseIf FindString(Mid(retour,Resultat,Len(retour)) , "Saturday" )
      jourshut = "samedi"
    ElseIf FindString(Mid(retour,Resultat,Len(retour)) , "Sunday" )
      jourshut = "dimanche"
    EndIf
    
  Else
    shutdown = #False
    sleep = #False
    restart = #False
    flagShutdown = #False
  EndIf 
  
  
EndProcedure


Procedure affheure1()
  Define zerohr.s, zero.s
  zerohr.s =""
  If hr < 10
    zerohr.s ="0"
  EndIf
  
  zero.s = ""
  If min < 10
    zero.s ="0"
  EndIf
  SetGadgetText(11,""+zerohr+hr+":"+zero+min) 
EndProcedure

Procedure affheure2()
  Define zerohr.s, zero.s
  
  zerohr.s =""
  If hrshut < 10
    zerohr.s ="0"
  EndIf
  
  zero.s =""
  If minshut < 10
    zero.s ="0"
  EndIf
  
  SetGadgetText(12,""+zerohr+hrshut+":"+zero + minshut) 
EndProcedure


Procedure About()
  OpenApropos() ; fenetre apropos type form
  SetGadgetText(AprosposVersion, "Version " + #Version+" - "+FormatDate("%dd/%mm/%yyyy", #PB_Compiler_Date) )   ;2022")   ; Affichage version dans A_Propos
  If LoadFont(0, "Arial", 48)
    SetGadgetFont(Apropos_titre, FontID(0))   ; Set the loaded Arial 16 font as new standard
  EndIf
  
EndProcedure

Procedure Param()
  OpenParam() ; fenetre apropos type form
              ;SetGadgetText(AprosposVersion, "Version " + #Version+" - "+FormatDate("%dd/%mm/%yyyy", #PB_Compiler_Date) )   ;2022")   ; Affichage version dans A_Propos
              ;If LoadFont(0, "Arial", 48)
              ;  SetGadgetFont(Apropos_titre, FontID(0))   ; Set the loaded Arial 16 font as new standard
              ;EndIf
  
EndProcedure


; fenetre 
Define  Y, quit, Event, type, horaire.s, fenetre
Y = 50
quit = 0;

;pmset(" -S pmset Repeat wake M 19:45:00","mot de passe");
;Delay (100)                                     ; laisse le temps de la prise en compte

;password =InputRequester("Mot de passe utilisteur", "s'il vous plait, entrez votre mot de passe", "")
password = LectureConfig()

; Debug "XXXXX"+ pmset("pmset -g sched",password.s)  ; pour vérifier le password
;End ; sortie
;EndIf  

LireEtat() ; lecture de la programmation

If OpenWindow(0, 0, 0, 450, 150+50, "Programmer", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  
  CreateMenu(30, WindowID(0))
  MenuItem(#PB_Menu_About, "A propos ...") 
  MenuItem(#PB_Menu_Preferences,"Réglage")
  
  ButtonGadget  (2, 270, 115+50, 90, 25, "Annuler")
  ButtonGadget  (1, 355, 115+50, 90, 25, "Appliquer")
  
  ;TextGadget(25, 10, 10, 430, 25, "Programmer votre Mac pour le démarrer, l'éteindre, le mettre en veille et ")
  ;TextGadget(26, 10, 25, 430, 25, "le réactiver à des heures spécifiques.")
  
  CheckBoxGadget(3, 10 , Y, 150, 25, "Démarrer ou réactiver")
  ComboBoxGadget(5, 170, Y+2, 140+20, 21 )
  AddGadgetItem(5, -1,"Jours de la semaine")
  AddGadgetItem(5, -1,"Week-ends")
  AddGadgetItem(5, -1,"Tous les jours")
  AddGadgetItem(5, -1,"lundi")
  AddGadgetItem(5, -1,"mardi")
  AddGadgetItem(5, -1,"mercredi")
  AddGadgetItem(5, -1,"jeudi")
  AddGadgetItem(5, -1,"vendredi")
  AddGadgetItem(5, -1,"samedi")
  AddGadgetItem(5, -1,"dimanche")
  DisableGadget(5, #True)
  TextGadget(6, 325+7, Y+2, 30, 25, "à")
  SpinGadget     (11, 350, Y, 80, 25, 0, 1000)
  SetGadgetState (11, 0) 
  SetGadgetText(11, "00:00")   ; définit la valeur initiale
  DisableGadget(11, #True)
  
  CheckBoxGadget(7, 10 , Y+40, 20, 25, "")
  ComboBoxGadget(9, 30, y+42, 140, 21 )
  AddGadgetItem(9, -1,"Suspendre")
  AddGadgetItem(9, -1,"Redémarrer")
  AddGadgetItem(9, -1,"Eteindre")
  DisableGadget(9, #True)
  ComboBoxGadget(8, 170, Y+42, 140+20, 21 )
  AddGadgetItem(8, -1,"Jours de la semaine")
  AddGadgetItem(8, -1,"Week-ends")
  AddGadgetItem(8, -1,"Tous les jours")
  AddGadgetItem(8, -1,"lundi")
  AddGadgetItem(8, -1,"mardi")
  AddGadgetItem(8, -1,"mercredi")
  AddGadgetItem(8, -1,"jeudi")
  AddGadgetItem(8, -1,"vendredi")
  AddGadgetItem(8, -1,"samedi")
  AddGadgetItem(8, -1,"dimanche")
  DisableGadget(8, #True)
  TextGadget(10, 325+7, Y+42, 30, 25, "à")  
  SpinGadget     (12, 350, Y+40, 80, 25, 0, 1000)
  SetGadgetState (12, 0) 
  SetGadgetText(12, "00:00")   ; définit la valeur initiale
  DisableGadget(12, #True)
  ;gestion du mot de passe
  
  
  ;init gadget
  If wake = #True
    SetGadgetState(3, #True)
    DisableGadget(5, #False)
    DisableGadget(11, #False)
  EndIf
  
  Debug "XX2 "+jour
  SetGadgetText(5, jour)
  affheure1()
  
  
  Debug ">>>>>>>>>>>>>>>>>>>>>>> "+shutdown
  
  If flagShutdown = #True
    SetGadgetState(7, #True)
    DisableGadget(8, #False)
    DisableGadget(9, #False)
    DisableGadget(12, #False)
    If shutdown
      SetGadgetText(9, "Eteindre")
    ElseIf sleep
      SetGadgetText(9, "Suspendre")
    ElseIf restart
      SetGadgetText(9, "Redémarrer")
    EndIf
  EndIf
  SetGadgetText(8, jourshut)
  affheure2()
  
  
  Repeat
    Event = WaitWindowEvent()
    type = EventType()
    
    Select Event
        
      Case #PB_Event_Menu
        Select EventMenu()
          Case #PB_Menu_About
            about()
          Case #PB_Menu_Preferences
            Param()            
        EndSelect
        
      Case #PB_Event_CloseWindow
        
        fenetre = GetActiveWindow()
        Select fenetre
          Case 0
            quit = 1
          Default
            CloseWindow (fenetre)
        EndSelect    
        
      Case #PB_Event_Gadget
        
        Debug "> "+EventGadget()+" "+type
        Select EventGadget() 
            
          Case Bp_password  ; suppression password par reglage
            password =""
            MessageRequester( "Mot de passe", "Effacement enregistré")
            
          Case 1 ; bouton OK
                        
            ;weekdays - a subset of MTWRFSU ("M" And "MTWRF" are valid strings)
            ;lire jour
            
            
            Select GetGadgetText(5)
              Case "Jours de la semaine"
                jour = "MTWRF"
              Case "Week-ends"
                jour = "SU"
              Case "Tous les jours"
                jour = "MTWRFSU"
              Case "lundi"
                jour = "M"
              Case "mardi"
                jour = "T"
              Case "mercredi"
                jour = "W"
              Case "jeudi"
                jour = "R"
              Case "vendredi"
                jour = "F"
              Case "samedi"
                jour = "S"
              Case "dimanche"
                jour = "U"
              Default
                jour  = ""
            EndSelect
            
            jourwake = jour
            
            Select GetGadgetText(8)
              Case "Jours de la semaine"
                jour = "MTWRF"
              Case "Week-ends"
                jour = "SU"
              Case "Tous les jours"
                jour = "MTWRFSU"
              Case "lundi"
                jour = "M"
              Case "mardi"
                jour = "T"
              Case "mercredi"
                jour = "W"
              Case "jeudi"
                jour = "R"
              Case "vendredi"
                jour = "F"
              Case "samedi"
                jour = "S"
              Case "dimanche"
                jour = "U"
              Default
                jour  = ""
            EndSelect
            
            jourshut = jour
            
            shutdown = #False
            sleep = #False
            restart = #False
            If flagShutdown
              Select GetGadgetText(9)
                Case "Eteindre"
                  shutdown = #True
                  CommandeShutdown = "shutdown"
                Case "Suspendre"
                  sleep = #True
                  CommandeShutdown = "sleep"
                Case "Redémarrer"
                  restart = #True
                  CommandeShutdown = "restart"
              EndSelect
            EndIf
            
            
            Debug flagShutdown
            Debug shutdown
            Debug sleep
            Debug restart
            
            
            If wake = #True And  flagShutdown = #False
              commandetexte = " -S pmset Repeat wakeorpoweron "+jourwake+" "+hr+":"+min+":00"
              pmset(commandetexte,password)
              Debug commandetexte
            EndIf
            If  wake = #False And flagShutdown = #True
              commandetexte = " -S pmset Repeat " + CommandeShutdown +" " + jourshut +" "+hrshut+":"+minshut+":00"
              pmset(commandetexte,password)
              Debug commandetexte
            EndIf
            If wake = #True And flagShutdown = #True 
              commandetexte.s = " -S pmset Repeat wakeorpoweron "+jourwake+" "+hr+":"+min+":00" + " " + CommandeShutdown + " "  + jourshut +" "+hrshut+":"+minshut+":00"
              pmset(commandetexte,password)
              Debug commandetexte
            EndIf
            If wake = #False And flagShutdown = #False
              commandetexte.s = " -S pmset Repeat cancel"
              pmset(commandetexte,password)
              Debug commandetexte
            EndIf
            CloseWindow(0)
            quit = 1  
          Case 2 ; bouton Annuller   
            quit = 1
          Case 3  ; check 
            If wake = #True
              DisableGadget(5, #True)
              DisableGadget(11, #True)
              wake = #False
            Else
              DisableGadget(5, #False)
              DisableGadget(11, #False)
              wake = #True
            EndIf
            
          Case 7  ; check shutdown
            If flagShutdown = #True
              DisableGadget(8, #True)
              DisableGadget(9, #True)
              DisableGadget(12, #True)
              flagShutdown = #False
            Else
              DisableGadget(8, #False)
              DisableGadget(9, #False)
              DisableGadget(12, #False)
              flagShutdown = #True
            EndIf        
            
          Case 11  ; type ^4 v5
            If type = 4
              hr +1
              If hr > 23 
                hr = 0
              EndIf
              affheure1()
              
            ElseIf type = 5
              hr-1
              If hr < 0
                hr = 23  
              EndIf
              affheure1()
            Else 
              horaire.s = GetGadgetText(11)
              hr = Val(Left(horaire, 2))
              min = Val(Right(horaire, 2))
            EndIf
            
          Case 12  ; type ^4 v5
            
            Debug "hrshut 1"+hrshut
            If type = 4
              hrshut +1
              If hrshut > 23 
                hrshut = 0
              EndIf
              affheure2()
            ElseIf type = 5
              hrshut -1
              If hrshut < 0
                hrshut = 23 
              EndIf
              affheure2()
            Else 
              horaire.s = GetGadgetText(12)
              hrshut = Val(Left(horaire, 2))
              minshut = Val(Right(horaire, 2))
            EndIf
            Debug "hrshut 2"+hrshut
        EndSelect
    EndSelect ; event main windows 0 
    
    
  Until quit = 1
EndIf
; IDE Options = PureBasic 6.01 LTS - C Backend (MacOS X - arm64)
; CursorPosition = 51
; FirstLine = 37
; Folding = --
; EnableXP
; UseIcon = Unknown.png
; Executable = Programmer_M1.app