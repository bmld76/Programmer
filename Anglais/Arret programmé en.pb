
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

XIncludeFile "Apropos en.pbf"      ; tamplate a propos (MAC)
XIncludeFile "Param en.pbf"        ; tamplate a propos (MAC)


DossierParametre =  GetUserDirectory(#PB_Directory_ProgramData) +"pmset"
ExistParametre =   ExamineDirectory(#PB_Any, DossierParametre, "")  ; O si non existant 
If ExistParametre = 0 
  If CreateDirectory(DossierParametre) = 0
  EndIf
EndIf
FichierParam = DossierParametre+"/"+"Config"  ; simple fichier texte

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
    CloseProgram(commande) ; Ferme la connexion vers le programme
  EndIf
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
        MessageRequester("", "Wrong password ")
        exit = 0
      ElseIf ReadErr$ =""
        If exit = 1
          ok = 1
          Debug "Out on error"
          ;sortie sur erreur mot de passe
          Break
        EndIf
      Else  
        If exit = 1
          ok = 0
          Debug "Out on error"
          ;sortie sur erreur mot de passe
          Break
        EndIf
      EndIf
      If password = ""
        pw.s =InputRequester("Password", "Specify the session password", "" ,  #PB_InputRequester_Password)
        
        SauvegardeConfig(pw)
      Else
        pw.s = password
      EndIf   
      If ProgramRunning(ProgramID)
        WriteProgramStringN(ProgramID, pw)
        exit = 1
      EndIf
    Wend
    ;End
  Else
    MessageRequester( "Hello", "Correct password")
  EndIf
    
EndProcedure


Procedure LireEtat()
  
  Define retour.s, Resultat, max, horaire.s
  
  retour.s = etat()

  Resultat = FindString(retour , "Repeating power events" )
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
  Debug "wakepoweron > "+ resultat
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
    
    If FindString(Left(retour,max) , "weekends" )
      jour = "Weekends" 
    ElseIf FindString(Left(retour,max) , "weekdays" )
      jour = "Weekdays" 
    ElseIf FindString(Left(retour,max) , "every day" )
      jour = "Everyday" 
    ElseIf FindString(Left(retour,max) , "Monday" )
      jour = "Monday"
    ElseIf FindString(Left(retour,max) , "Tuesday" )
      jour = "Tuesday"
    ElseIf FindString(Left(retour,max) , "Wednesday" )
      jour = "Wednesday"
    ElseIf FindString(Left(retour,max) , "Thursday" )
      jour = "Thursday"
    ElseIf FindString(Left(retour,max) , "Friday" )
      jour = "Friday"
    ElseIf FindString(Left(retour,max) , "Saturday" )
      jour = "Saturday"
    ElseIf FindString(Left(retour,max) , "Sunday" )
      jour = "Sunday"
    EndIf
  Else
    wake = #False
  EndIf  
  
  
  ; shutdown
  ;Debug "jour " + jour + " retour "+retour
  Debug "shut : >>>>> "+Right(retour,max)
  
  
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
    Debug "shutdown >"+ resultat +" "+shutdown +" "+sleep+" "+restart
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
    
    Debug ">>>>>>>>>>> "+horaire
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
      jourshut = "Weekends" 
    ElseIf FindString(Mid(retour,Resultat,Len(retour)) , "weekdays" )
      jourshut = "Weekdays" 
    ElseIf FindString(Mid(retour,Resultat,Len(retour)) , "every day" )
      jourshut = "Everyday" 
    ElseIf FindString(Mid(retour,Resultat,Len(retour)) , "Monday" )
      jourshut = "Monday"
    ElseIf FindString(Mid(retour,Resultat,Len(retour)) , "Tuesday" )
      jourshut = "Tuesday"
    ElseIf FindString(Mid(retour,Resultat,Len(retour)) , "Wednesday" )
      jourshut = "Wednesday"
    ElseIf FindString(Mid(retour,Resultat,Len(retour)) , "Thursday" )
      jourshut = "Thursday"
    ElseIf FindString(Mid(retour,Resultat,Len(retour)) , "Friday" )
      jourshut = "Friday"
    ElseIf FindString(Mid(retour,Resultat,Len(retour)) , "Saturday" )
      jourshut = "Saturday"
    ElseIf FindString(Mid(retour,Resultat,Len(retour)) , "Sunday" )
      jourshut = "Sunday"
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

EndProcedure


; fenetre 
Define  Y, quit, Event, type, horaire.s, fenetre
Y = 50
quit = 0;

password = LectureConfig()

LireEtat() ; lecture de la programmation

If OpenWindow(0, 0, 0, 450, 150+50, "Schedule", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  
  CreateMenu(30, WindowID(0))
  MenuItem(#PB_Menu_About, "About ...") 
  MenuItem(#PB_Menu_Preferences,"Setting")
  
  ButtonGadget  (2, 270, 115+50, 90, 25, "Cancel")
  ButtonGadget  (1, 355, 115+50, 90, 25, "Apply")
  
  ;TextGadget(25, 10, 10, 430, 25, "Programmer votre Mac pour le démarrer, l'éteindre, le mettre en veille et ")
  ;TextGadget(26, 10, 25, 430, 25, "le réactiver à des heures spécifiques.")
  
  CheckBoxGadget(3, 10 , Y, 150, 25, "Start up or wake")
  ComboBoxGadget(5, 170, Y+2, 140+20, 21 )
  AddGadgetItem(5, -1,"Weekdays")
  AddGadgetItem(5, -1,"Weekends")
  AddGadgetItem(5, -1,"Everydays")
  AddGadgetItem(5, -1,"Monday")
  AddGadgetItem(5, -1,"Tuesday")
  AddGadgetItem(5, -1,"Wednesday")
  AddGadgetItem(5, -1,"Thursday")
  AddGadgetItem(5, -1,"Friday")
  AddGadgetItem(5, -1,"Saturday")
  AddGadgetItem(5, -1,"Sunday")
  DisableGadget(5, #True)
  TextGadget(6, 325+7, Y+2, 30, 25, "at")
  SpinGadget     (11, 350, Y, 80, 25, 0, 1000)
  SetGadgetState (11, 0) 
  SetGadgetText(11, "00:00")   ; définit la valeur initiale
  DisableGadget(11, #True)
  
  CheckBoxGadget(7, 10 , Y+40, 20, 25, "")
  ComboBoxGadget(9, 30, y+42, 140, 21 )
  AddGadgetItem(9, -1,"Sleep")
  AddGadgetItem(9, -1,"Restart")
  AddGadgetItem(9, -1,"Shutdown")
  DisableGadget(9, #True)
  ComboBoxGadget(8, 170, Y+42, 140+20, 21 )
  AddGadgetItem(8, -1,"Weekdays")
  AddGadgetItem(8, -1,"Weekends")
  AddGadgetItem(8, -1,"Everyday")
  AddGadgetItem(8, -1,"Monday")
  AddGadgetItem(8, -1,"Tuesday")
  AddGadgetItem(8, -1,"Wednesday")
  AddGadgetItem(8, -1,"Thursday")
  AddGadgetItem(8, -1,"Friday")
  AddGadgetItem(8, -1,"Saturday")
  AddGadgetItem(8, -1,"Sunday")
  DisableGadget(8, #True)
  TextGadget(10, 325+7, Y+42, 30, 25, "at")  
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
  
  SetGadgetText(5, jour)
  affheure1()
  
  If flagShutdown = #True
    SetGadgetState(7, #True)
    DisableGadget(8, #False)
    DisableGadget(9, #False)
    DisableGadget(12, #False)
    If shutdown
      SetGadgetText(9, "Shutdown")
    ElseIf sleep
      SetGadgetText(9, "Sleep")
    ElseIf restart
      SetGadgetText(9, "Restart")
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
            MessageRequester( "Password", "Registered deletion")
            
          Case 1 ; bouton OK
                        
            ;lire jour
            
 
            Select GetGadgetText(5)
              Case "Weekdays"
                jour = "MTWRF"
              Case "Weekends"
                jour = "SU"
              Case "Everydays"
                jour = "MTWRFSU"
              Case "Monday"
                jour = "M"
              Case "Tuesday"
                jour = "T"
              Case "Wenesday"
                jour = "W"
              Case "Thursday"
                jour = "R"
              Case "Friday"
                jour = "F"
              Case "Saturday"
                jour = "S"
              Case "Sunday"
                jour = "U"
              Default
                jour  = ""
            EndSelect
            
            jourwake = jour
            
            Select GetGadgetText(8)
              Case "Weekdays"
                jour = "MTWRF"
              Case "Weekends"
                jour = "SU"
              Case "Everydays"
                jour = "MTWRFSU"
              Case "Monday"
                jour = "M"
              Case "Tuesday"
                jour = "T"
              Case "Wenesday"
                jour = "W"
              Case "Thursday"
                jour = "R"
              Case "Friday"
                jour = "F"
              Case "Saturday"
                jour = "S"
              Case "Sunday"
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
                Case "Shutdown"
                  shutdown = #True
                  CommandeShutdown = "shutdown"
                Case "Sleep"
                  sleep = #True
                  CommandeShutdown = "sleep"
                Case "Restart"
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
        EndSelect
    EndSelect ; event main windows 0 

  Until quit = 1
EndIf
; IDE Options = PureBasic 6.01 LTS - C Backend (MacOS X - arm64)
; CursorPosition = 345
; FirstLine = 345
; Folding = --
; EnableXP
; UseIcon = Unknown.png
; Executable = Schedule_M1.app