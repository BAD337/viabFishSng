breed [boats boat]
breed [villages village]
globals [
   distance-village  ;; Distance d'une zone donnée par rapport au village                   4444
  zone-pêche-radius  ;; Rayon de la zone de pêche autour du village                         444
  rentabilite_senegalais_total
  rentabilite_etrangers_total                        ;             444444444444444
  distance_senegalais
  distance_etrangers
  biomasse_senegalais
  biomasse_etrangers
  prix_du_poisson
  cout_deplacement
  PropBiomassPeche  ;; Proportion de la biomasse capturée (en pourcentage)      #########
  CostPerUnitDistance  ;; Coût par unité de distance parcourue        ###############
  PricePerKg  ;; Prix du poisson par kilogramme                ###########
  distance-rentabilite   ;; Liste pour stocker les distances                       #####
  rentabilite_senegalais ;; Liste des rentabilités pour les pêcheurs sénégalais           #####
  rentabilite_etrangers   ;; Liste des rentabilités pour les pêcheurs étrangers          ######
  rentabilite_senegalais-temp
  rentabilite_etrangers-temp   ;   ########

  ;; GIS Data
  myEnvelope
  lac
  place
  exclusionPeche
  lakeCells
  ;; global init variables
  r ; annual growth rate
  k ; carrying capacity in kg
  kLakeCell ; carrying capacity in kg per lake patch
  diffuseBiomass ; %
  InitHeading ; direction initiale des pirogues
  ;; global output
  sumBiomass ; biomasse du lac
  capital_total_1 ; somme des capitaux des pêcheurs Sénégalais
  capital_total_2 ; somme des capitaux des pêcheurs étrangers
  capital_moyen_1 ; capital moyen d'un pêcheur Sénégalais
  capital_moyen_2 ; capital moyen d'un pêcheur étranger
  capitalTotal
  biomassfished
  t1
  t2

  meanMST         ; mean sojourn time on captial MST for for all boat
  medianMFET      ; median exit time on capital  MFET for all boat

  MSTb
  MSTb_l ; list of ticks
  MSTc
  MSTc_l ; list of ticks

  MFETb
  MFETc
]
turtles-own [                                   ;                                    44
  type-de-pecheur  ;; Local ou étranger
  rentabilite  ;; Rentabilité du pêcheur
  ;zone  ;; Zone de pêche du pêcheur
]                                                  ;                                 444



patches-own[
 lake ; bol
 excluPeche ; bol
 excluPecheCells ; bol
 biomass ; kg
]

villages-own[
  lakeVillage ;; bol
]

boats-own[
 ;myVillage
  team ; bol
  ReleveFilet
  capture
  capture_totale
  capital
  capital_total
  firstExitSatifaction  ;; if 9999  = NA  MFET in mathias et al. 2024
  AST                   ;; mean sojourn time  in Mathias et al. 2024 as list
  ASTc                  ;; a count on MST to have one number per boat [
  origine            ;; Origine du pêcheur : "endogene" ou "exogene" ;                      ##
  distance-max-pêche ;; Distance maximale de pêche pour ce pêcheur       ;                  ##
  village-attached      ;; Village auquel le pêcheur est rattaché                           ;##
  rayon-deplacement     ;; Rayon de déplacement pour le pêcheur (local ou étranger)  ;       ##
]


extensions [gis]

to InitiVar
  set r r_i;;0.015 pour rakya
  set k BiomassInit;;((900000 * 1000) / 2144) ; / 1000 pour les tonnes
  set diffuseBiomass diffB_i ;;0.5
  set InitHeading random 360
  set MSTc_l []
  set MSTb_l []
  set CostPerUnitDistance 5 ;; Exemple : 5 unités monétaires par unité de distance parcourue            ########
  set PropBiomassPeche 10 ;; Exemple : 10% de la biomasse est capturée à chaque pêche        ############
  set PricePerKg 5  ;; Exemple : Le prix du poisson est de 5 unités monétaires par kilogramme         #######
end

to setup
  clear-all
  ;reset-ticks
  set rentabilite_senegalais_total 0  ;; Initialisation de la rentabilité totale des sénégalais          4444444444
  set rentabilite_etrangers_total 0  ;; Initialisation de la rentabilité totale des étrangers            4444
  set rentabilite_senegalais []  ;; Liste vide des rentabilités des pêcheurs sénégalais   ###
  set rentabilite_etrangers []    ;; Liste vide des rentabilités des pêcheurs étrangers
  set rentabilite_senegalais-temp 0
  set rentabilite_etrangers-temp 0
  set CostPerUnitDistance 2  ;; Par exemple, 2 unités monétaires par distance        44444444444
  set PropBiomassPeche 0.5  ;; 50% de la biomasse du patch
  set PricePerKg 10         ;; Prix du poisson en unité monétaire        4444444444444


  set distance-rentabilite []    ;; Liste vide pour stocker les distances

  set prix_du_poisson 10  ;; prix du poisson
  set zone-pêche-radius 5  ;; Par exemple, une zone de pêche de rayon 5 autour du village       444444

   ;; Créer des pêcheurs (tortues)
  create-boats 50 [
    set color red  ;; Exemple de couleur pour les pêcheurs sénégalais
    set type-de-pecheur "senegalais"                                            ;          44444
    set rentabilite random 100
    setxy random-xcor random-ycor  ;; Positionner au hasard                              4444
    ;set zone random 30  ;; Positionner les pêcheurs dans la zone proche du village        444444'
  ]
  create-boats 50 [
    set color green ;; Exemple de couleur pour les pêcheurs étrangers
    set type-de-pecheur "etranger"                                                               ; 4444
    set rentabilite random 100                                                       ;           44444444
    setxy random-xcor random-ycor  ;; Positionner au hasard                  44444444
    ;set zone random 30  ;; Positionner les pêcheurs dans la zone proche du village        ;             444444444
  ]

  InitiVar

  set myEnvelope gis:load-dataset "data/envelope.shp"
  set lac gis:load-dataset "data/lac.shp"
  set place gis:load-dataset "data/villages.shp"
  set exclusionPeche gis:load-dataset "data/zoneExclusionPeche.shp"
  setup-world-envelope

  ask patches [
    set pcolor gray
    set lake FALSE
    set excluPecheCells FALSE
  ]

  ask patches gis:intersecting place [
    sprout-villages 1 [
      set shape "circle"
      set color yellow
    ]
  ]

  ask patches gis:intersecting lac [
    set pcolor blue
    set lake TRUE
    set excluPecheCells FALSE
    set excluPeche FALSE
  ]

  ask patches gis:intersecting exclusionPeche [
      set lake TRUE
      set excluPecheCells TRUE
      set excluPeche FALSE
  ]

  if ZonesExclusionPeche [
  ask patches with[excluPecheCells = TRUE][
      set pcolor green
      set excluPeche TRUE
  ]]

  ;; Biomasse par patch

  set lakeCells patches with[lake = TRUE]
  let nblakeCells count lakeCells
  set kLakeCell (k / nblakeCells)
  ask lakeCells [
    set biomass kLakeCell
  ]

  ask patches with[lake = FALSE][set biomass 0]


  ;; Nombre de pirogue par village
  ;; Dans chaque village en bord de lac, il y a une même proportion de pêcheurs Sénégalais et étrangers
  ;; Création des nouvelles tortues / pirogues sur les patch sélectionnés / là où se situent les villages de bord de lac

  ask villages [
    ifelse any? patches with[pcolor = blue or pcolor = green] in-radius 5 [
      set lakeVillage TRUE
    ][
     set lakeVillage FALSE
    ]
  ]

  let _nbBoatVillage ((nbBoats / count villages with[lakeVillage = TRUE]))
  ;show _nbBoatVillage ;; pour vérifier si l'arrondi tombe juste

  ask villages with[lakeVillage = TRUE][                                                                        ;###
    let _nearestPatch min-one-of (patches with [pcolor = blue or pcolor = green])[distance myself]
    move-to _nearestPatch ;; on déplace les villages près de l'eau

  ;let _nbBoatVillage ((nbBoats / count villages with[lakeVillage = TRUE]))

  ;; Créer les bateaux sénégalais (endogènes)
  ask patch-here [
    sprout-boats precision(_nbBoatVillage * (ProportionSenegalais / 100)) 0 [
      set color red
      set shape "fisherboat"
      set team 1
      set origine "endogene"  ;; Pêcheur sénégalais
      set distance-max-pêche 18 ;; Distance maximale de pêche pour les pêcheurs locaux (par exemple, 5 km)
      set rayon-deplacement 6 ;; Rayon de déplacement limité autour du village
      set village-attached myself ;; Rattacher ce pêcheur au village
      set capital_total capital_totalI
      set firstExitSatifaction 0
      set AST []
    ]
  ]

  ;; Créer les bateaux étrangers (exogènes)
  ask patch-here [
    sprout-boats precision((_nbBoatVillage * (1 - (ProportionSenegalais / 100)))) 0 [
      set color green
      set shape "fisherboat"
      set team 2
      set origine "exogene"  ;; Pêcheur étranger
      set distance-max-pêche 25 ;; Distance maximale de pêche pour les pêcheurs étrangers (par exemple, 10 km)
      set rayon-deplacement 10;; Rayon de déplacement plus large
      set village-attached nobody ;; Pas de village attaché pour les étrangers
      set capital_total capital_totalI
      set firstExitSatifaction 0
      set AST []
    ]
  ]
]                                                                                                                         ;####

reset-ticks
  statSummary

end

to setup-world-envelope
gis:set-world-envelope (gis:envelope-of myEnvelope)
end

to go
  ;; Calculer les interactions entre les pêcheurs locaux et étrangers                             444444444444444
  ask turtles [
    ;; Calculer la rentabilité individuelle
    set rentabilite random 100

    ;; Interaction avec les autres pêcheurs
    let voisins turtles in-radius zone-pêche-radius  ;; Trouver les voisins dans la zone de pêche
    let conflict-or-collaboration 0

    ;; Vérifier s'il y a un conflit ou une collaboration
    if any? voisins [
      if [type-de-pecheur] of one-of voisins = "senegalais" and type-de-pecheur = "etranger" [
        ;; Si un pêcheur sénégalais et un étranger sont proches, on a un conflit
        set rentabilite rentabilite - 10
        set conflict-or-collaboration "Conflit"
      ]
    if [type-de-pecheur] of one-of voisins = "etranger" and type-de-pecheur = "senegalais" [
        ;; Si un pêcheur étranger et un sénégalais sont proches, on a une collaboration
        set rentabilite rentabilite + 5
        set conflict-or-collaboration "Collaboration"
      ]
    ]
     ;; Suivi de la rentabilité totale pour chaque groupe
    if type-de-pecheur = "senegalais" [
      set rentabilite_senegalais_total rentabilite_senegalais_total + rentabilite
    ]
    if type-de-pecheur = "etranger" [
      set rentabilite_etrangers_total rentabilite_etrangers_total + rentabilite
    ]
  ]
    ;; Ajouter les données au graphique
  set-current-plot "Interactions et Rentabilité"  ;; Assurez-vous que le graphique s'appelle "Rentabilité"
  plotxy ticks rentabilite_senegalais_total  ;; Ajouter la rentabilité totale des sénégalais
  plotxy ticks rentabilite_etrangers_total  ;; Ajouter la rentabilité totale des étrangers


     ;; Tracer l'interaction
   ; if conflict-or-collaboration = "Conflit" [
   ;   set color red  ;; Changer la couleur en rouge en cas de conflit
   ; ]
   ; if conflict-or-collaboration = "Collaboration" [
   ;   set color green  ;; Changer la couleur en vert en cas de collaboration
   ; ]
                        ;                                                       4444444444444444444444444


 ifelse ZonesExclusionPeche [
    ask lakeCells with[excluPecheCells = TRUE] [set excluPeche TRUE]
    ask lakeCells with[excluPeche = TRUE][
      set pcolor scale-color green biomass 0 kLakeCell
  ]
  ask lakeCells with[excluPeche = FALSE][
      set pcolor scale-color blue biomass 0 kLakeCell
  ]][
    ask lakeCells with[excluPecheCells = TRUE] [set excluPeche FALSE]
    ask lakeCells with[excluPeche = FALSE][
      set pcolor scale-color blue biomass 0 kLakeCell
  ]]

  ;print sumBiomass
  ;print sumtest

  ;diffuse biomass diffuseBiomass

  ask lakeCells [
    diffuse_biomass
  ]

  ;statSummary
  ;print sumBiomass
  ;print sumtest

  ask lakeCells [
    grow-biomass
    ;set pcolor scale-color blue biomass 0 (k / count lakeCells)
    ; quand c'est blanc c'est qu'il y a beaucoup de poisson vs noir plus de poisson
  ]

  ;statSummary
  ;print sumBiomass
  ;print sumtest


  ; hypothese que mbanais et maliens ne posent pas leurs filets aux mêmes endroits
  ; et ne pechent pas autant de poisson par jour
  ask boats [
    fishingEtrangers   ;                           ##########
    fishingSenegalais  ;                        #############

  ifelse team = 1
    [
      set ReleveFilet 0 ; 1 relève de filet correspond à une relève de filet sur 1 patch (donc 12 relèves de filet = 1 filet de 3 km)
    set capture_totale 0 ; chaque jour capture initialement 0
    set capital_total capital_total - CoutMaintenance ; cout de sortie par jour
    set capital_total_1 0
    ;set capture 0
    ;set capital 0

    ; 1 tick = 1 journée

    ; pour la mise en place d'une réserve intégrale
    ; si reserve integrale = 4 mois, on peut pêcher 8 mois = 8 * 30 jours
    ifelse ticks mod 360 < ((12 - ReserveIntegrale) * 30)[
      move

    ; pirogue sur un seul patch alors que peche sur 3km de filet donc on fait une boucle pour que la pirogue aille sur plusieurs patch en 1 journée
    ; slider pour le nombre de patch sachant que 1 patch = 250 mètres = 0.25 km donc 12 patch = 3000 mètres = 3 km
    ; tant que les pêcheurs n'ont pas pêcher 1 filet de 3km = tant que relève filet inférieur à 12,
    ; ils continuent de pêcher
     while [ReleveFilet < (LongueurFilet / 250)][
      ;if ReleveFilet < (LongueurFilet / 250)[
      fishingSenegalais
      set capture_totale min (list (capture_totale + capture) QtéMaxPoissonPirogue)
      ;if capture_totale < QtéMaxPoissonPirogue [
      ;while [capture_totale < QtéMaxPoissonPirogue][

      ;set capture_totale capture_totale + capture
      ;set capital_total capital_total + capital
      set capital_total capital_total + capture_totale * PrixPoisson
      ;print capture_totale
      ;print capital_total
      ; 0.8 kg / biomass du patch pour avoir une capture en kg sur 250m (10 kg sur 3000 m donc 0.8 kg sur 250m)
      set ReleveFilet ReleveFilet + 1
      moveForward
      ]

    ][
      set capture 0
      set capture_totale capture_totale + capture
      set capital_total capital_total + capital
    ]
    calculSatisfaction
    set capital_total_1 capital_total_1 + capital_total
    ] ;; fin du if team = 1
    [ ;; debut du if team = 2
      set ReleveFilet 0
    set capture_totale 0
    set capital_total capital_total - CoutMaintenance
    set capital_total_2 0
    ;set capture 0
    ;set capital 0
    ;set capital 0

    ; 1 tick = 1 journée

    ; pour la mise en place de la réserve intégrale
    ; si reserve integrale = 4 mois, peche autorisee pendant 8 mois = 8*30 jours
      ifelse ticks mod 360 < ((12 - ReserveIntegrale) * 30)[
        move

        ; pirogue sur un seul patch alors que peche sur 3km de filet donc on fait une boucle pour que la pirogue aille sur plusieurs patch en 1 journée
        ; slider pour le nombre de patch sachant que 1 patch = 250 mètres = 0.25 km donc 12 patch = 3000 mètres = 3 km
        ; maliens pechent plus donc 1.5 * filet
        while [ReleveFilet < (LongueurFiletEtrangers / 250)][
          fishingEtrangers
          set capture_totale min (list (capture_totale + capture) QtéMaxPoissonPirogueEtrangers)
          set capital_total capital_total + capture_totale * PrixPoisson
          ;let _fishAvalableHere [biomass] of patch-here
          set ReleveFilet ReleveFilet + 1
          moveForward
          ;set capital capital + max list (PrixPoisson *  ((CaptureEtrangers / 12) * _fishAvalableHere) - CoutMaintenance) 0
        ]
      ][
        set capture 0
        set capture_totale capture_totale + capture
        set capital_total capital_total + capital
      ]
    set capital_total_2 capital_total_2 + capital_total
    calculSatisfaction
    ]

  ]
  ; move ;; Déplacer le bateau vers une zone avec biomasse                 ###########
;    fishing ;; Pêcher une fois arrivé                                 ################
  caluclG
  if sumBiomass <= 0[stop]
  statSummary

  ;print sumtest
   ;; Calculer la rentabilité totale          #################
  let total_profit sum [capital_total] of boats    ;###########
  print total_profit            ;############"



  ;; Définir la liste des distances à tester
let liste_distances [5 15 30]

;; Initialiser un indice pour itérer à travers la liste
let i 0

repeat (length liste_distances) [
  ;; Obtenir la distance courante
  let dist item i liste_distances

  ;; Calculer la rentabilité pour les pêcheurs sénégalais
  ask turtles with [color = red] [
    let rentabilite_senegalais-local calculer_rentabilite self dist "senegalais"
    set rentabilite_senegalais-temp rentabilite_senegalais-temp + rentabilite_senegalais-local
  ]

  ;; Calculer la rentabilité pour les pêcheurs étrangers
  ask turtles with [color = green] [
    let rentabilite_etrangers-local calculer_rentabilite self dist "etranger"
    set rentabilite_etrangers-temp rentabilite_etrangers-temp + rentabilite_etrangers-local
  ]

  ;; Ajouter les résultats à la liste des rentabilités
  set rentabilite_senegalais lput rentabilite_senegalais-temp rentabilite_senegalais
  set rentabilite_etrangers lput rentabilite_etrangers-temp rentabilite_etrangers

  ;; Réinitialiser les variables temporaires pour la prochaine distance
  set rentabilite_senegalais-temp 0
  set rentabilite_etrangers-temp 0

  ;; Incrémenter l'indice pour passer à la distance suivante
  set i i + 1
]

;; Tracer les résultats des rentabilités
 plot-rentabilite
  tick
end

to calculate-rentabilite
  ;; Initialisation des variables globales avec des listes vides
  set rentabilite_senegalais []  ;; Liste vide pour les rentabilités des sénégalais
  set rentabilite_etrangers []  ;; Liste vide pour les rentabilités des étrangers

  ;; Définition des distances sénégalaises et étrangères
  let distances_senegalais [5 15 30]   ;; Liste des distances pour les sénégalais
  let distances_etrangers [10 20 25]  ;; Liste des distances pour les étrangers

  ;; Liste des distances à tester
  let distances [5 15 30]
end

to move       ;                                               #####################
  ; Déplacer vers un patch cible
  move-to one-of lakeCells with[excluPeche = FALSE]

  if origine = "endogene" [
    ; Pêcheur sénégalais : rester proche du village (rayon limité autour du village)
    let max-distance rayon-deplacement  ;; Rayon de déplacement pour les pêcheurs locaux
    let max-patches max-distance / 0.25 ;; Conversion en nombre de patches
    let patches-moved 0

    ;; Déplacer dans un rayon autour du village
    while [patches-moved < max-patches] [
      let target-patch min-one-of patches in-radius max-distance [distance myself]  ;; Calcul de la distance par rapport à la tortue (bateau)
      if target-patch != nobody [
        move-to target-patch
        set patches-moved patches-moved + 1
      ]
    ]
  ]

  if origine = "exogene" [
    ;; Pêcheur étranger : plus grande liberté de mouvement (rayon étendu)
    let max-distance rayon-deplacement  ;; Rayon de déplacement plus large pour les étrangers
    let max-patches max-distance / 0.25 ;; Conversion en nombre de patches
    let patches-moved 0

    ;; Se déplacer librement dans la zone disponible
    while [patches-moved < max-patches] [
      let target-patch min-one-of patches with [biomass > 0] [distance myself]  ;; Calcul correct de la distance
      if target-patch != nobody [
        move-to target-patch
        set patches-moved patches-moved + 1
      ]
    ]
  ]
;; Déplacer vers un patch avec biomasse
  let target-patch min-one-of patches with [biomass > 0] [distance myself]
  if target-patch != nobody [
    let dist distance target-patch
    move-to target-patch
    ;; Calculer le coût du déplacement : plus la distance est grande, plus le coût est élevé
    let cost (dist * CostPerUnitDistance) ;; Coût en fonction de la distance (en énergie ou en temps)
     ;; Ajouter le coût au capital du pêcheur
    set capital_total capital_total - cost ;; Le coût est déduit du capital total du pêcheur
  ]


end             ;                                                             #############





;; les pecheurs avancent dans une même direction : modelise lorsqu'ils relevent leurs filets
to moveForward
  ;pour dessiner les pecheurs
  ;pen-down

  set heading heading + (random 45 - random 45 + 1)

  let patch_ahead patch-at-heading-and-distance heading 1
  ;show is_fishable? patch_ahead

  ifelse is_fishable? patch_ahead = FALSE [
    set heading random -180
    let patch_ahead_turn patch-at-heading-and-distance heading 1
    if is_fishable? patch_ahead_turn = TRUE[ forward 1]
  ][
    forward 1]

  ;show is_fishable? patch_ahead

  ;pen-up
end

to-report is_fishable? [patch_ahead]
  let fishable? FALSE

  ask patch_ahead [
    if excluPeche = FALSE
  [set fishable? TRUE]
  ]

  report fishable?



end


to fishingSenegalais
  let _fishAvailable [biomass] of patch-here               ;                             ########################
  let catch (PropBiomassPeche / 100) * _fishAvailable ;; Proportion de la biomasse capturée
  set capture catch

  ;; Réduire la biomasse disponible sur le patch
  ask patch-here [
    set biomass _fishAvailable - catch
  ]
    ;; Calculer la rentabilité : capture x prix - coût du déplacement
  set capital_total capital_total + (catch * PricePerKg) - (CostPerUnitDistance * distance self)

  ;                                                           ######################
  let _fishAvalableHere [biomass] of patch-here

  ; Proportion de poisson capturée par le filet sur le patch
  let PropCaptureSenegalais (PropBiomassPecheSenegalais / 100) * [biomass] of patch-here

  ask patch-here[
    set biomass (_fishAvalableHere - PropCaptureSenegalais) ; biomass en kg ??????
  ]

  set capture PropCaptureSenegalais
  ;set capital (PrixPoisson * capture)

  ; captureSenegalais est en kg par filet donc on divisait par 12 pour l'avoir par patch
  ;ifelse _fishAvalableHere > (captureSenegalais / 12 ) [
    ;ask patch-here [
      ;set biomass (_fishAvalableHere - (captureSenegalais / 12 )) ; 3000m/250m = 12
  ;]
  ;set capture (captureSenegalais / 12)
  ;set capital (PrixPoisson * capture) - CoutMaintenance
  ;]
  ;[ ask patch-here [
  ;  set biomass max list (_fishAvalableHere - (captureSenegalais / 12 )) 0
  ;  ]
  ;  set capture max list(_fishAvalableHere) 0
  ;  set capital (PrixPoisson * capture) - CoutMaintenance
  ;]

end

to fishingEtrangers
  let _fishAvailable [biomass] of patch-here               ;                             ########################
  let catch (PropBiomassPeche / 100) * _fishAvailable ;; Proportion de la biomasse capturée
  set capture catch

  ;; Réduire la biomasse disponible sur le patch
  ask patch-here [
    set biomass _fishAvailable - catch
  ]
    ;; Calculer la rentabilité : capture x prix - coût du déplacement
  set capital_total capital_total + (catch * PricePerKg) - (CostPerUnitDistance * distance self)

  ;                                                           ######################

  let _fishAvalableHere [biomass] of patch-here

  ; Proportion de poisson capturée par le filet sur le patch
  let PropCaptureEtrangers (PropBiomassPecheEtrangers / 100) * [biomass] of patch-here

  ask patch-here[
    set biomass (_fishAvalableHere - PropCaptureEtrangers) ; biomass en kg ??????
  ]

  set capture PropCaptureEtrangers
  ;set capital (PrixPoisson * capture)
  ;ifelse _fishAvalableHere > (captureEtrangers / 12 ) [
  ;  ask patch-here [
  ;    set biomass (_fishAvalableHere - (captureEtrangers / 12 )) ; 3000m/250m = 12
  ;]
  ;set capture (captureEtrangers / 12)
  ;]
  ;[ ask patch-here [
  ;  set biomass max list (_fishAvalableHere - (captureEtrangers / 12 )) 0
  ;  ]
  ;  set capture max list(_fishAvalableHere) 0
  ;]

end

to diffuse_biomass ; patch procedure
  let _previousBiomass biomass
  let _neighbourTerre count neighbors with[lake = FALSE]

  let _previousBiomassNeighboursLake sum [(1 / 8 * diffuseBiomass * biomass)] of neighbors with[lake = TRUE]
  ;print _previousBiomassNeighboursLake

  set biomass (1 - diffuseBiomass) * _previousBiomass + (1 / 8 * _neighbourTerre * diffuseBiomass * biomass) + _previousBiomassNeighboursLake
  ;print biomass
  ;print kLakeCell
end

to grow-biomass  ; patch procedure
  if biomass > 0 [
    let _previousBiomass biomass
    ;show word "premier terme" (r * _previousBiomass)
    ; show word "sec terme" (1 - (_previousBiomass / k))
    set biomass _previousBiomass + (r * _previousBiomass * (1 - (_previousBiomass / kLakeCell))) ; effort pecheurs de l'equation de Rakya est inclu dans la previousBiomass
  ]
end

to calculSatisfaction
  if capital_total > SatisfactionCapital AND firstExitSatifaction = 0 [
    set firstExitSatifaction ticks
  ]

  ;; mean sojourn time calculation
  if capital_total > SatisfactionCapital [
    set AST lput ticks AST
    set ASTc length AST
  ]


end

to-report calculer_rentabilite [pecheur dist pecheur-type]
  ;; Calculer le coût de déplacement
  let cout-deplacement (CostPerUnitDistance * dist)

  ;; Calculer la biomasse capturée sur le patch
  let biomasse-capturee (PropBiomassPeche * [biomass] of patch-here)

  ;; Calculer le revenu en fonction de la biomasse capturée et du prix
  let revenu (biomasse-capturee * PricePerKg)

  ;; Initialisation de la rentabilité
  ;let rentabilite 0

  ;; Calcul de la rentabilité en fonction du type de pêcheur
  if pecheur-type = "senegalais" [
    set rentabilite revenu - cout-deplacement  ;; Rentabilité pour les pêcheurs sénégalais
  ]

  if pecheur-type = "etranger" [
    set rentabilite revenu - cout-deplacement  ;; Rentabilité pour les pêcheurs étrangers
  ]

  ;; Retourner la rentabilité calculée
  report rentabilite
end

to plot-rentabilite
  ;; Créer le graphique "Rentabilité" et configurer l'axe X et Y
 ;
set-current-plot "Rentabilité"
  clear-plot

  ;; Rentabilité des pêcheurs sénégalais (couleur rouge)
  set-plot-pen-color red
  ask turtles with [color = red] [
    let distances [1 2 3 4 5 6 7 8 9 10  11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30]
    let i 0 ;; Initialiser l'index
    while [i < length distances] [
      let dist item i distances ;; Accéder à l'élément à l'index i
      let rentabilite_senegalais_local calculer_rentabilite self dist "senegalais"
      plotxy dist rentabilite_senegalais_local
      set i i + 1 ;; Incrémenter l'index
    ]
  ]

  ;; Rentabilité des pêcheurs étrangers (couleur verte)
  set-plot-pen-color green
  ask turtles with [color = green] [
    let distances [1 2 3 4 5 6 7 8 9 10  11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30]
    let i 0 ;; Initialiser l'index
    while [i < length distances] [
      let dist item i distances ;; Accéder à l'élément à l'index i
      let rentabilite_etrangers_local calculer_rentabilite self dist "etranger"
      plotxy dist rentabilite_etrangers_local
      set i i + 1 ;; Incrémenter l'index
    ]
  ]
end


;to plot-rentabilite             ###########################################################################################
 ; ;; Créer un graphique (plot) s'il n'en existe pas déjà
  ;set-current-plot "Rentabilité"  ;; Nom du graphique
  ;set-plot-x-range 0 30           ;; Plage de l'axe X (par exemple de 0 à 30 pour les distances)
  ;set-plot-y-range 0 200       ;; Plage de l'axe Y (ajustez cette plage en fonction des résultats que vous attendez)

;  clear-plot ;; Effacer les anciennes courbes

  ;; Trace la rentabilité des pêcheurs sénégalais
 ; plotxy 5 (item 0 rentabilite_senegalais) ;; distance 5 pour les pêcheurs sénégalais
  ;plotxy 15 (item 1 rentabilite_senegalais) ;; distance 15 pour les pêcheurs sénégalais
  ;plotxy 30 (item 2 rentabilite_senegalais) ;; distance 30 pour les pêcheurs sénégalais

  ;; Trace la rentabilité des pêcheurs étrangers
  ;plotxy 5 (item 0 rentabilite_etrangers) ;; distance 5 pour les pêcheurs étrangers
  ;plotxy 15 (item 1 rentabilite_etrangers) ;; distance 15 pour les pêcheurs étrangers
  ;plotxy 30 (item 2 rentabilite_etrangers) ;; distance 30 pour les pêcheurs étrangers
;end              #######################################################################################################""""""


to caluclG
  ;;MST et MFET a l'échelle de la simu
  ;; ces indicateurs sont compatible avec le papier de Mathias et al 2024
  set satifsactionCapitalG SatisfactionCapital * nbBoats

  if sumBiomass < satisfactionBiomassG AND MFETb = 0 [
    set MFETb ticks
  ]
  if sumBiomass < satisfactionBiomassG AND ticks > 0 [
    ;  MSTb
    set MSTb_l lput ticks MSTb_l
    set MSTb (length MSTb_l) / ticks
  ]


  if sum [capital_total] of boats > satifsactionCapitalG AND MFETc = 0 [
    set MFETc ticks
  ]

  if sum [capital_total] of boats > satifsactionCapitalG  AND ticks > 0[
    ;  MSTc
    set MSTc_l lput ticks MSTc_l
    set MSTc (length MSTc_l) / ticks
  ]

end

to statSummary
  set sumBiomass sum [biomass] of lakeCells
  ;set sumtest sum [biomass] of patches with[lake = FALSE]
  if any? boats with [team = 1] [
    set capital_moyen_1 mean[capital_total] of boats with [team = 1]
  ]
  ;print capital_moyen_1
  ;set capital_moyen_2 (capital_total_2 / count boats with [team = 2])
  if any? boats with [team = 2] [
    set capital_moyen_2 mean[capital_total] of boats with [team = 2]
  ]
  ;print capital_moyen_2
  set biomassfished sum[capture] of boats
  set capitalTotal capital_moyen_1 + capital_moyen_2
  if any? boats AND ticks > 0 [
    set meanMST mean[ASTc] of boats / ticks
    set medianMFET median[firstExitSatifaction] of boats
  ]
end
