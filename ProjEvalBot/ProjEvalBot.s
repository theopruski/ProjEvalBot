		;; RK - Evalbot (Cortex M3 de Texas Instrument)
; programme - Pilotage 2 Moteurs Evalbot par PWM tout en ASM (Evalbot tourne sur lui m�me)



		AREA    |.text|, CODE, READONLY

; This register controls the clock gating logic in normal Run mode
SYSCTL_PERIPH_GPIO EQU		0x400FE108	; SYSCTL_RCGC2_R (p291 datasheet de lm3s9b92.pdf)
	
; The GPIODATA register is the data register
GPIO_PORTF_BASE		EQU		0x40025000	; GPIO Port F (APB) base: 0x4002.5000 (p416 datasheet de lm3s9B92.pdf)

; The GPIODATA register is the data register
GPIO_PORTD_BASE		EQU		0x40007000		; GPIO Port D (APB) base: 0x4000.7000 (p416 datasheet de lm3s9B92.pdf)
GPIO_PORTE_BASE		EQU		0x40024000		; GPIO Port E (APB) base: 0x4002.4000 (p416 datasheet de lm3s9B92.pdf)

; configure the corresponding pin to be an output
; all GPIO pins are inputs by default
GPIO_O_DIR   		EQU 	0x00000400  ; GPIO Direction (p417 datasheet de lm3s9B92.pdf)

; The GPIODR2R register is the 2-mA drive control register
; By default, all GPIO pins have 2-mA drive.
GPIO_O_DR2R   		EQU 	0x00000500  ; GPIO 2-mA Drive Select (p428 datasheet de lm3s9B92.pdf)

; Digital enable register
; To use the pin as a digital input or output, the corresponding GPIODEN bit must be set.
GPIO_O_DEN  		EQU 	0x0000051C  ; GPIO Digital Enable (p437 datasheet de lm3s9B92.pdf)

; Pul_up
GPIO_I_PUR   		EQU 	0x00000510  ; GPIO Pull-Up (p432 datasheet de lm3s9B92.pdf)

; Broches select
BROCHE4				EQU		0x10		; led1 sur broche 4
BROCHE5				EQU		0x20		; led2 sur broche 5
BROCHE4_5			EQU		0x30		; led1 & led2 sur broche 4 et 5
BROCHE6				EQU 	0x40		; bouton poussoir1
BROCHE7				EQU		0x80		; bouton poussoir2
BROCHE6_7			EQU		0xC0		; bouton poussoir1 & bouton poussoir2 sur broche 6 et 7
BROCHE0 			EQU		0x01		; bumper1 
BROCHE1				EQU		0x02		; bumper2
BROCHE0_1			EQU		0x03		; bumper1 & bumper2 sur broche 0 et 1

DUREE   			EQU     0x0020000F ;0x002FFFFF
	
		ENTRY
		EXPORT	__main
		
		;; The IMPORT command specifies that a symbol is defined in a shared object at runtime.
		IMPORT	MOTEUR_INIT					; initialise les moteurs (configure les pwms + GPIO)
		
		IMPORT	MOTEUR_DROIT_ON				; activer le moteur droit
		IMPORT  MOTEUR_DROIT_OFF			; d�activer le moteur droit
		IMPORT  MOTEUR_DROIT_AVANT			; moteur droit tourne vers l'avant
		IMPORT  MOTEUR_DROIT_ARRIERE		; moteur droit tourne vers l'arri�re
		IMPORT  MOTEUR_DROIT_INVERSE		; inverse le sens de rotation du moteur droit
		
		IMPORT	MOTEUR_GAUCHE_ON			; activer le moteur gauche
		IMPORT  MOTEUR_GAUCHE_OFF			; d�activer le moteur gauche
		IMPORT  MOTEUR_GAUCHE_AVANT			; moteur gauche tourne vers l'avant
		IMPORT  MOTEUR_GAUCHE_ARRIERE		; moteur gauche tourne vers l'arri�re
		IMPORT  MOTEUR_GAUCHE_INVERSE		; inverse le sens de rotation du moteur gauche


__main	

		; ;; Enable the Port F & D peripheral clock 		(p291 datasheet de lm3s9B96.pdf)
		; ;;									
		ldr r6, = SYSCTL_PERIPH_GPIO  			;; RCGC2
        mov r0, #0x00000038  					;; Enable clock sur GPIO D, E et F o� sont branch�s les leds (0x38 == 0b101000)
		; ;;														 									      	(GPIO::FEDCBA)
        str r0, [r6]
		
		; ;; "There must be a delay of 3 system clocks before any GPIO reg. access  (p413 datasheet de lm3s9B92.pdf)
		nop	   									;; tres tres important....
		nop	   
		nop	   									;; pas necessaire en simu ou en debbug step by step...
	
		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION LED

        ldr r6, = GPIO_PORTF_BASE+GPIO_O_DIR    ;; 1 Pin du portF en sortie (broche 4 : 00010000)
        ldr r0, = BROCHE4_5	
        str r0, [r6]
		
		ldr r6, = GPIO_PORTF_BASE+GPIO_O_DEN	;; Enable Digital Function 
        ldr r0, = BROCHE4_5
        str r0, [r6]
		
		ldr r6, = GPIO_PORTF_BASE+GPIO_O_DR2R	;; Choix de l'intensit� de sortie (2mA)
        ldr r0, = BROCHE4_5		
        str r0, [r6]
		
		mov r2, #0x000       					;; pour eteindre LED
		;vvvvvvvvvvvvvvvvvvvvvvvFin configuration LED 
		
		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION Switch

		ldr r7, = GPIO_PORTD_BASE+GPIO_I_PUR	;; Pul_up 
        ldr r0, = BROCHE6_7
        str r0, [r7]
		
		ldr r7, = GPIO_PORTD_BASE+GPIO_O_DEN	;; Enable Digital Function 
        ldr r0, = BROCHE6_7
        str r0, [r7]     
		
		ldr r7, = GPIO_PORTD_BASE + (BROCHE6<<2)  ;; @data Register = @base + (mask<<2) ==> Switcher
		;vvvvvvvvvvvvvvvvvvvvvvvFin configuration Switch 
		
		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION Bumper

		ldr r8, = GPIO_PORTE_BASE+GPIO_I_PUR	;; Pul_up 
        ldr r0, = BROCHE0_1
        str r0, [r8]
		
		ldr r8, = GPIO_PORTE_BASE+GPIO_O_DEN	;; Enable Digital Function 
        ldr r0, = BROCHE0_1
        str r0, [r8]     
		
		ldr r8, = GPIO_PORTE_BASE + (BROCHE0_1<<2)  ;; @data Register = @base + (mask<<2) ==> Switcher
		;vvvvvvvvvvvvvvvvvvvvvvvFin configuration Bumper

		; Configure les PWM + GPIO
		BL	MOTEUR_INIT	   	

; V�rifie l'�tat du bouton et continue uniquement lorsque le bouton est enfonc�
ReadState
		
		; Charge la valeur du bouton dans le registre r10
		; Compare la valeur du bouton avec la position enfonc�
		ldr r10,[r7]
		CMP r10, #0x00
		BNE ReadState
		
		; Active les moteurs droit et gauche
		BL	MOTEUR_DROIT_ON
		BL	MOTEUR_GAUCHE_ON
		
; Boucle de pilotage des 2 Moteurs
loop	
		; Evalbot avance droit devant
		BL	MOTEUR_DROIT_AVANT	   
		BL	MOTEUR_GAUCHE_AVANT

		; Avancement pendant une p�riode (deux WAIT)
		BL	WAIT	; BL (Branchement vers le lien WAIT); possibilit� de retour � la suite avec (BX LR)
		BL	WAIT

		b	loop

; Boucle d'attante
WAIT	
		; D�lai d'attente 
		ldr r1, =0x1FFFF
		
; Boucle d'attente d'une action
wait	

		; V�rifie si le bouton 1 est enfonc� pour red�marrer le robot (apr�s le bouton 2)
		ldr r7, = GPIO_PORTD_BASE + (BROCHE6<<2)  ;; @data Register = @base + (mask<<2) ==> Switcher
		ldr r10,[r7]
		CMP r10,#0x00
		BEQ ActionBouton1
		
		; V�rifie si le bouton 2 est enfonc� pour arr�ter le robot
		ldr r7, = GPIO_PORTD_BASE + (BROCHE7<<2)  ;; @data Register = @base + (mask<<2) ==> Switcher
		ldr r10,[r7]
		CMP r10,#0x00
		BEQ.W ActionBouton2
		
		; V�rifie si le bumper droit est enfonc�, �teint les LEDs, allume la LED lorsqu'il est rel�ch�, attend, et red�marre
		ldr r4, = GPIO_PORTE_BASE + (BROCHE0<<2)  ;; @data Register = @base + (mask<<2) ==> Switcher
		ldr r10,[r4]
		CMP r10,#0x00
		BEQ.W ActionBumperDroit
		
		; V�rifie si si le bumper gauche est enfonc�, �teint les LEDs, allume la LED lorsqu'il est rel�ch�, attend, et red�marre
		ldr r4, = GPIO_PORTE_BASE + (BROCHE1<<2)  ;; @data Register = @base + (mask<<2) ==> Switcher
		ldr r10,[r4]
		CMP r10,#0x00
		BEQ.W ActionBumperGauche

		; D�cr�mente la valeur de d�lai
		subs r1, #1
		
        bne wait 

		;; retour � la suite du lien de branchement
		BX	LR

; Actions associ�es � l'appui du bouton 1
ActionBouton1
		; Active les moteurs droit et gauche
		BL MOTEUR_DROIT_ON
		BL MOTEUR_GAUCHE_ON
		
		B loop

; Actions associ�es � l'appui du bouton 2
ActionBouton2
		; D�sactive les moteurs droit et gauche
		BL MOTEUR_DROIT_OFF
		BL MOTEUR_GAUCHE_OFF
		
		; Initialise la valeur � 0 pour �teindre les LEDs associ�es (broches 4 et 5)
		mov r2, #0
		ldr r4, = GPIO_PORTF_BASE + (BROCHE4_5<<2)	
		str r2, [r4]
		
		B loop

; Actions associ�es � l'appui du bumper droit
ActionBumperDroit
		; D�sactive les moteurs droit et gauche
		BL MOTEUR_DROIT_OFF
		BL MOTEUR_GAUCHE_OFF
		
		; �teint la LED associ�e (broche 4)
		ldr r4, = GPIO_PORTF_BASE + (BROCHE4<<2)
		mov r2, #BROCHE4
		str r2, [r4] 
		; Attend la dur�e sp�cifi�e
        ldr r1, = DUREE

wait_d1	subs r1, #1
        bne wait_d1
		
		BL	WAIT	; BL (Branchement vers le lien WAIT); possibilit� de retour � la suite avec (BX LR)
		BL	WAIT
		
		; Inverse les moteurs droit et gauche
		BL MOTEUR_DROIT_INVERSE
		BL MOTEUR_GAUCHE_INVERSE
		
		; Attend la dur�e sp�cifi�e pour la boucle wait_d1
        ldr r1, = DUREE

wait_d2	subs r1, #1
        bne wait_d2
; Obstacle rencontrer � droite
		BL MOTEUR_DROIT_OFF
		BL MOTEUR_GAUCHE_OFF
		
		BL	WAIT	; BL (Branchement vers le lien WAIT); possibilit� de retour � la suite avec (BX LR)
		BL	WAIT
		
		BL MOTEUR_DROIT_ON
		BL MOTEUR_GAUCHE_ON
		
		BL	WAIT	; BL (Branchement vers le lien WAIT); possibilit� de retour � la suite avec (BX LR)
		BL	WAIT
		
		BL MOTEUR_DROIT_OFF
		BL MOTEUR_GAUCHE_ON
		
		BL	WAIT	; BL (Branchement vers le lien WAIT); possibilit� de retour � la suite avec (BX LR)
		BL	WAIT
		
		BL MOTEUR_DROIT_AVANT
		BL MOTEUR_GAUCHE_AVANT
		
		BL	WAIT	; BL (Branchement vers le lien WAIT); possibilit� de retour � la suite avec (BX LR)
		BL	WAIT
		
		BL MOTEUR_DROIT_ON
		BL MOTEUR_GAUCHE_OFF
		
		BL	WAIT	; BL (Branchement vers le lien WAIT); possibilit� de retour � la suite avec (BX LR)
		BL	WAIT
		
		BL MOTEUR_DROIT_ON
		BL MOTEUR_GAUCHE_OFF
		
		BL	WAIT	; BL (Branchement vers le lien WAIT); possibilit� de retour � la suite avec (BX LR)
		BL	WAIT
		
		BL MOTEUR_DROIT_OFF
		BL MOTEUR_GAUCHE_ON
		
		BL	WAIT	; BL (Branchement vers le lien WAIT); possibilit� de retour � la suite avec (BX LR)
		BL	WAIT
		
		BL MOTEUR_DROIT_OFF
		BL MOTEUR_GAUCHE_ON
		
		BL	WAIT	; BL (Branchement vers le lien WAIT); possibilit� de retour � la suite avec (BX LR)
		BL	WAIT
		
		BL MOTEUR_DROIT_ON
		BL MOTEUR_GAUCHE_ON

; Clignotement de la LED associ�e (broche 4)
blinky_d
		; Allume la LED associ�e (broche 4)
		ldr r4, = GPIO_PORTF_BASE + (BROCHE4<<2)
		mov r2, #BROCHE4
		str r2, [r4]

		; Attend la dur�e sp�cifi�e pour la boucle WAIT
		ldr r1, =DUREE
		BL WAIT

		; �teint la LED associ�e (broche 4)
		ldr r4, = GPIO_PORTF_BASE + (BROCHE4<<2)
		mov r2, #0         ; Valeur pour �teindre la LED
		str r2, [r4]

		; Attend la dur�e sp�cifi�e pour la boucle WAIT
		ldr r1, =DUREE
		BL WAIT 
		
		; D�cr�mente le nombre de clignotements restants
		subs r5, r5, #1
		bne blinky_d
		
		B loop

; Actions associ�es � l'appui du bumper gauche
ActionBumperGauche
		; D�sactive les moteurs droit et gauche
		BL MOTEUR_DROIT_OFF
		BL MOTEUR_GAUCHE_OFF
		
		; �teint la LED associ�e (broche 5)
		ldr r4, = GPIO_PORTF_BASE + (BROCHE5<<2)
		mov r2, #BROCHE5
		str r2, [r4]
		; Attend la dur�e sp�cifi�e
        ldr r1, = DUREE

wait_g1	subs r1, #1
        bne wait_g1
		
		BL	WAIT	; BL (Branchement vers le lien WAIT); possibilit� de retour � la suite avec (BX LR)
		BL	WAIT
		
		; Inverse les moteurs droit et gauche
		BL MOTEUR_DROIT_INVERSE
		BL MOTEUR_GAUCHE_INVERSE
		
		; Attend la dur�e sp�cifi�e pour la boucle wait_g1
        ldr r1, = DUREE

wait_g2	subs r1, #1
        bne wait_g2
; Obstacle rencontrer � gauche
		BL MOTEUR_DROIT_OFF
		BL MOTEUR_GAUCHE_OFF
		
		BL	WAIT	; BL (Branchement vers le lien WAIT); possibilit� de retour � la suite avec (BX LR)
		BL	WAIT
		
		BL MOTEUR_DROIT_ON
		BL MOTEUR_GAUCHE_ON
		
		BL	WAIT	; BL (Branchement vers le lien WAIT); possibilit� de retour � la suite avec (BX LR)
		BL	WAIT
		
		BL MOTEUR_DROIT_ON
		BL MOTEUR_GAUCHE_OFF
		
		BL	WAIT	; BL (Branchement vers le lien WAIT); possibilit� de retour � la suite avec (BX LR)
		BL	WAIT
		
		BL MOTEUR_DROIT_AVANT
		BL MOTEUR_GAUCHE_AVANT
		
		BL	WAIT	; BL (Branchement vers le lien WAIT); possibilit� de retour � la suite avec (BX LR)
		BL	WAIT
		
		BL MOTEUR_DROIT_OFF
		BL MOTEUR_GAUCHE_ON
		
		BL	WAIT	; BL (Branchement vers le lien WAIT); possibilit� de retour � la suite avec (BX LR)
		BL	WAIT
		
		BL MOTEUR_DROIT_OFF
		BL MOTEUR_GAUCHE_ON
		
		BL	WAIT	; BL (Branchement vers le lien WAIT); possibilit� de retour � la suite avec (BX LR)
		BL	WAIT
		
		BL MOTEUR_DROIT_ON
		BL MOTEUR_GAUCHE_OFF
		
		BL	WAIT	; BL (Branchement vers le lien WAIT); possibilit� de retour � la suite avec (BX LR)
		BL	WAIT
		
		BL MOTEUR_DROIT_ON
		BL MOTEUR_GAUCHE_OFF
		
		BL	WAIT	; BL (Branchement vers le lien WAIT); possibilit� de retour � la suite avec (BX LR)
		BL	WAIT
		
		BL MOTEUR_DROIT_ON
		BL MOTEUR_GAUCHE_ON

; Clignotement de la LED associ�e (broche 5)
blinky_g
		; Allume la LED associ�e � la broche 5
		ldr r4, = GPIO_PORTF_BASE + (BROCHE5<<2)
		mov r2, #BROCHE5   ; Valeur pour allumer la LED
		str r2, [r4]

		ldr r1, =DUREE
		BL WAIT

		; �teint la LED associ�e (broche 5)
		ldr r4, = GPIO_PORTF_BASE + (BROCHE5<<2)
		mov r2, #0         ; Valeur pour �teindre la LED
		str r2, [r4]

		; Attend la dur�e sp�cifi�e pour la boucle WAIT
		ldr r1, =DUREE
		BL WAIT

		; D�cr�mente le nombre de clignotements restants
		subs r5, r5, #1
		bne blinky_g

		B loop
		
		NOP
		NOP
        END
			