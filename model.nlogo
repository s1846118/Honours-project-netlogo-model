;; IDEA -> Perceived knowledge on a topic determines if you are for against
turtles-own ; ADDED
[
 perceived-knowledge ; Number between 0-1
 factual-knowledge ; Number between 0-1
 share-misinformation? ; The user will either share the post or not
 belief-misinformation ; How much does someone believe in something? More they believe more they share.
 share-information? ; Same for true information
 belief-information ; Same for true information
 su-neighbours
 mis-exposed?
 true-exposed?
 for-topic
 initial-diffusers?
]


;;
;; PREFERENCIAL ATTATCHMENT
;;

;;;;;;;;;;;;;;;;;;;;;;;;
;;; Setup Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

to setup2
  clear-all
  set-default-shape turtles "circle"
  ;; make the initial network of two turtles and an edge
  make-node nobody        ;; first node, unattached
  make-node turtle 0      ;; second node, attached to first node
end

;;;;;;;;;;;;;;;;;;;;;;;
;;; Main Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;

to go2
  ;; new edge is green, old edges are gray
  ask links [ set color gray ]
  make-node find-partner         ;; find partner & use it as attachment
                                 ;; point for new node
  if layout? [ layout ]
end

;; used for creating a new node
to make-node [old-node]
  create-turtles 1
  [
    set color red
    if old-node != nobody
      [ create-link-with old-node [ set color green ]
        ;; position the new node near its partner
        move-to old-node
        fd 8
      ]
  ]
end

;; This code is the heart of the "preferential attachment" mechanism, and acts like
;; a lottery where each node gets a ticket for every connection it already has.
;; While the basic idea is the same as in the Lottery Example (in the Code Examples
;; section of the Models Library), things are made simpler here by the fact that we
;; can just use the links as if they were the "tickets": we first pick a random link,
;; and than we pick one of the two ends of that link.
to-report find-partner
  report [one-of both-ends] of one-of links
end

;;;;;;;;;;;;;;
;;; Layout ;;;
;;;;;;;;;;;;;;

;; resize-nodes, change back and forth from size based on degree to a size of 1
to resize-nodes
  ifelse all? turtles [size <= 1]
  [
    ;; a node is a circle with diameter determined by
    ;; the SIZE variable; using SQRT makes the circle's
    ;; area proportional to its degree
    ask turtles [ set size sqrt count link-neighbors ]
  ]
  [
    ask turtles [ set size 1 ]
  ]
end

to layout
  ;; the number 3 here is arbitrary; more repetitions slows down the
  ;; model, but too few gives poor layouts
  repeat 3 [
    ;; the more turtles we have to fit into the same amount of space,
    ;; the smaller the inputs to layout-spring we'll need to use
    let factor sqrt count turtles
    ;; numbers here are arbitrarily chosen for pleasing appearance
    layout-spring turtles links (1 / factor) (7 / factor) (1 / factor)
    display  ;; for smooth animation
  ]
  ;; don't bump the edges of the world
  let x-offset max [xcor] of turtles + min [xcor] of turtles
  let y-offset max [ycor] of turtles + min [ycor] of turtles
  ;; big jumps look funny, so only adjust a little each time
  set x-offset limit-magnitude x-offset 0.1
  set y-offset limit-magnitude y-offset 0.1
  ask turtles [ setxy (xcor - x-offset / 2) (ycor - y-offset / 2) ]
end

to-report limit-magnitude [number limit]
  if number > limit [ report limit ]
  if number < (- limit) [ report (- limit) ]
  report number
end

;;
;;
;; END
;; PREFERENCIAL ATTATCHMENT END
;; END
;;
;;

to setup ; ADDED
  setup2
  while [(count turtles) < agents] [
    go2
  ]
  ask turtles [
    set color blue
    set share-misinformation?  false
    set share-information?  false

  ]
  setup-agents
;;  set-agent-properties
;;  initialise-diffusion
  reset-ticks
end

to go
;;  if ticks = 1500
;;    [ stop ]
  believe-and-share-model-true
  believe-and-share-model-mis

  if (ticks mod 5 = 0) [
    ask turtles [
      set perceived-knowledge perceived-knowledge - 3
      set factual-knowledge factual-knowledge - 3
    ]
  ]
  tick
end

;;
;; CHANGE THIS TO USE PREFERENCIAL ATTATCHEMENT NODES
;;
to setup-agents ; ADDED
  ask n-of media-agents turtles
  [
    let x random 2
    (ifelse
      x = 0 [; Malicious news agent
        set share-misinformation? true
        set color red
      ]
      x = 1 [
        set share-information? true
        set color green
      ]
      [
        set color blue
      ])
  ]
end

to set-agent-properties
  ask turtles
  [
   let flip-coin random 100
   if flip-coin < 11 ; High knowledge & high or low perceived knowledge
    [
      let x random 2
      set factual-knowledge 90
      if x = 1
      [
        set perceived-knowledge 90
      ]
      if x = 0
      [
        set perceived-knowledge 10
      ]
    ]
   if flip-coin > 10 and flip-coin < 40 ; Medium to high factual and medium to low perceived
    [
     set factual-knowledge 60
     set perceived-knowledge 40
    ]

   if flip-coin > 40 and flip-coin < 60 ; Low factual low perceived
    [
     set factual-knowledge 20
     set perceived-knowledge 20
    ]
   if flip-coin > 60 and flip-coin < 80 ; Med to low factual and med to high perceived
    [
     set factual-knowledge 40
     set perceived-knowledge 60
    ]
   if flip-coin > 80; High perceived low factual
    [
     set factual-knowledge 10
     set perceived-knowledge 90
    ]

    set share-misinformation? false
    set share-information? false
    set true-exposed? false
    set mis-exposed? false

    let fc random 3 ;; Half should be for the topic and half should not

    if fc = 0 [
      set for-topic 0
      set belief-information 0
      set belief-misinformation 0
    ] ;; Undecided
    if fc = 1 [
      set for-topic 1
      set belief-information 500
    ] ;; For
    if fc = 2 [
      set for-topic 2
      set belief-misinformation 500
    ] ;; Against

  ]
end

to initialise-diffusion ; Ask all su breed agents if they are neighbours with a mass media agent if so they are exposed to information
  ask turtles
  [
    let media-distribution random 2
    if initial-diffusers? = true
    [
      if media-distribution = 0 ; News agent exposing neighbors to credible information
      [
        ask in-link-neighbors [
          set true-exposed? true
        ]
      ]
      if media-distribution = 1 ; News agent exposing neighbors to misinformation
      [
        ask in-link-neighbors [
          set mis-exposed? true
        ]

      ]
    ]
  ]
end

to believe-and-share-model-mis ;; We assume that you only share some information once.
  ask turtles
  [
    if share-misinformation? = false and count ( in-link-neighbors with [ share-misinformation? = true ] ) > 0; ;; This agent is somewhat exposed to misinformation
    [
      set mis-exposed? true
      let exposed count ( in-link-neighbors with [ share-misinformation? = true ] )

      ;; Now either the agent will just share (behavioural reaction) or they will increase belief and then share (cognitive followed by behavioural reaction)

      ;; Share (path 3) -> As described in the literature their is a possibility that a user may simply share some information without increasing belief in the topic
      ;; The sharing model says this is due to 1. Risk factors and 2. Exposure to misinformation
      ;; To share misinformation without increasing belief in the topic one must be:
      ;; Undecided & low factual and perceived knowledge
      let coin random 1000
;      (ifelse
;        perceived-knowledge < 20 and factual-knowledge < 20 and for-topic = 0 and (coin - exposed) <= 100 [ ;; Low perceived & Factual knowledge & Undecided
;         set share-misinformation? true ;; 20% Chance of this category of person sharing without considering belief.
;         set color red
;        ]
;        perceived-knowledge >= 20 and factual-knowledge >= 20 and for-topic != 2 and (coin - exposed) <= 25 and factual-knowledge < 70[
;          set share-misinformation? true
;          set color red
;;        ])

      ;; Belief (Path 1) - Here we go through all possible attributes of our agents and define how this effects their beleive
      (ifelse
        factual-knowledge >= 90 [ ;; High knowledge and high or low perceived knowledge for or against the topic
        set belief-misinformation (belief-misinformation - 5) ;; Reduce belief in misinformation if well informed
        ]
        perceived-knowledge < 20 and factual-knowledge < 20 [ ;; Low perceived and factual knowledge
          (ifelse
            for-topic = 0 [ ;; Undecided and low factual and perceived knoweldge means you may or may not share misinformation
              if (coin - exposed) <= 500 [
                set belief-misinformation (belief-misinformation + 5)
                set perceived-knowledge (perceived-knowledge + 5)
              ]

              if (coin - exposed) > 500 [ ;; Person does not believe the misinformation
                set belief-misinformation (belief-misinformation - 5)
              ]
            ]
            for-topic = 2 [ ;; For topic and low factual and perceived knowledge = Slightly more likely to beleive in topic
              if (coin - exposed) <= 550 [
                set belief-misinformation (belief-misinformation + 5)
                set perceived-knowledge (perceived-knowledge + 5)
              ]
              if (coin - exposed) > 550 [ ;; Person does not believe the misinformation
                set belief-misinformation (belief-misinformation - 5)
              ]
            ]
            for-topic = 1 [ ;; Against topic with low factual and perceived knowledge = slightly less likely to b&s however still in the middle
              if (coin - exposed) <= 450 [
                set belief-misinformation (belief-misinformation + 5)
                set perceived-knowledge (perceived-knowledge + 5)
              ]
              if (coin - exposed) > 450 [ ;; Person does not believe the misinformation
                set belief-misinformation (belief-misinformation - 5)
              ]
            ])
        ]
        perceived-knowledge > 90 and factual-knowledge < 20 [ ;; High perceived and low factual knowledge
          (ifelse
            (for-topic = 0 or for-topic = 2)[ ;; Undecided or for and high perceived and low factual
              if (coin - exposed) <= 850 [
                set belief-misinformation (belief-misinformation + 5)
                set perceived-knowledge (perceived-knowledge + 5)
              ]

              if (coin - exposed) > 850 [ ;; Person does not believe the misinformation
                set belief-misinformation (belief-misinformation - 5)
              ]
            ]
            for-topic = 1 [ ;; Against and low factual and perceived knoweldge means you may or may not share misinformation. Against the topic
              if (coin + exposed) <= 100 [
                set belief-misinformation (belief-misinformation + 5)
                set perceived-knowledge (perceived-knowledge + 5)
              ]
              if (coin - exposed) > 100 [ ;; Person does not believe the misinformation
                set belief-misinformation (belief-misinformation - 5)
              ]
            ])
        ]
        [ ;; else-commands - This is any agent who is of middle to high or middle to low perceived and factual knowledge
          (ifelse
            for-topic = 1 [
              if (coin - (exposed)) < 400 [ ;; Against and middle range perceived and factual knowledge means not likely to share or increase belief.
                set belief-misinformation (belief-misinformation + 5)
                set perceived-knowledge (perceived-knowledge + 5)
              ]
              if (coin - (exposed)) > 400 [
                set belief-misinformation (belief-misinformation - 5) ;; Do not believe in the misinformation
              ]
            ]
            for-topic = 2 [
              if (coin - (exposed)) < 600 [ ;; For and middle range perceived and factual knowledge means not likely to share or increase belief.
                set belief-misinformation (belief-misinformation + 5)
                set perceived-knowledge (perceived-knowledge + 5)
              ]
              if (coin - (exposed)) >= 600 [
                set belief-misinformation (belief-misinformation - 5) ;; Do not believe in the misinformation
              ]
            ]
            for-topic = 0 [
              if (coin - (exposed)) < 500 [ ;; Undecided and middle range perceived and factual knowledge means not likely to share or increase belief.
                set belief-misinformation (belief-misinformation + 5)
                set perceived-knowledge (perceived-knowledge + 5)
              ]
              if (coin - (exposed)) >= 500 [
                set belief-misinformation (belief-misinformation - 5) ;; Do not believe in the misinformation
              ]
            ])
        ])
        ]
    if belief-misinformation > 800 and share-misinformation? = false  and belief-information < 300[
      set share-misinformation? true
      set color red
    ]
    ;; Changing belief
    if for-topic = 2 and belief-misinformation < 150 and belief-information > 500[
      set for-topic 1
    ]
    if for-topic = 2 and belief-misinformation < 150 and belief-information < 500[
      set for-topic 0
    ]
;;    if belief-misinformation <= 50 and share-misinformation? = true  [
;;      set share-misinformation? false
;;      set color blue
;;  ]
  ]
end

to believe-and-share-model-true ;; We assume that you only share some information once.
  ask turtles
  [
    if share-information? = false and count ( in-link-neighbors with [ share-information? = true ] ) > 0; ;; This agent is somewhat exposed to misinformation
    [
      set true-exposed? true
      let true-exposed count ( in-link-neighbors with [ share-information? = true ] )

      ;; Now either the agent will just share (behavioural reaction) or they will increase belief and then share (cognitive followed by behavioural reaction)

      ;; Share (path 3) -> As described in the literature their is a possibility that a user may simply share some information without increasing belief in the topic
      ;; The sharing model says this is due to 1. Risk factors and 2. Exposure to misinformation
      ;; To share misinformation without increasing belief in the topic one must be:
      ;; Undecided & low factual and perceived knowledge
      let coin random 1000
;      (ifelse
;        perceived-knowledge < 20 and factual-knowledge < 20 and for-topic = 0 and (coin - true-exposed) <= 200 [ ;; Low perceived & Factual knowledge & Undecided
;         set share-information? true ;; 20% Chance of this category of person sharing without considering belief.
;         set color green
;        ]
;        perceived-knowledge >= 20 and factual-knowledge >= 20 and for-topic != 2 and (coin - true-exposed) <= 25 and factual-knowledge < 80[
;          set share-information? true
;          set color green
;        ])

      ;; Belief (Path 1) - Here we go through all possible attributes of our agents and define how this effects their beleive
      (ifelse
        factual-knowledge >= 80 [ ;; High knowledge and high or low perceived knowledge for or against the topic
        set belief-information (belief-information + 5) ;; Reduce belief in misinformation if well informed
        ]
        perceived-knowledge < 20 and factual-knowledge < 20 [ ;; Low perceived and factual knowledge
          (ifelse
            for-topic = 0 [ ;; Undecided and low factual and perceived knoweldge means you may or may not share misinformation
              if (coin - true-exposed) <= 500 [
                set belief-information (belief-information + 5)
                set factual-knowledge (factual-knowledge + 5)
              ]

              if (coin - true-exposed) > 500 [ ;; Person does not believe the misinformation
                set belief-information (belief-information - 5)
              ]
            ]
            for-topic = 1 [ ;; For topic and low factual and perceived knowledge = Slightly more likely to beleive in topic
              if (coin - true-exposed) <= 550 [
                set belief-information (belief-information + 5)
                set factual-knowledge (factual-knowledge + 5)
              ]
              if (coin - true-exposed) > 550 [ ;; Person does not believe the misinformation
                set belief-information (belief-information - 5)
              ]
            ]
            for-topic = 2 [ ;; Against topic with low factual and perceived knowledge = slightly less likely to b&s however still in the middle
              if (coin - true-exposed) <= 450 [
                set belief-information (belief-information + 5)
                set factual-knowledge (factual-knowledge + 5)
              ]
              if (coin - true-exposed) > 450 [ ;; Person does not believe the misinformation
                set belief-information (belief-information - 5)
              ]
            ])
        ]
        perceived-knowledge > 80 and factual-knowledge < 20 [ ;; High perceived and low factual knowledge
          (ifelse
            (for-topic = 0 or for-topic = 1)[ ;; Undecided or for and high perceived and low factual
              if (coin - true-exposed) <= 850 [
                set belief-information (belief-information + 5)
                set factual-knowledge (factual-knowledge + 5)
              ]

              if (coin - true-exposed) > 850 [ ;; Person does not believe the misinformation
                set belief-information (belief-information - 5)
              ]
            ]
            for-topic = 2 [ ;; Against and low factual and perceived knoweldge means you may or may not share misinformation. Against the topic
              if (coin + true-exposed) <= 150 [
                set belief-information (belief-information + 5)
                set factual-knowledge (factual-knowledge + 5)
              ]
              if (coin - true-exposed) > 150 [ ;; Person does not believe the misinformation
                set belief-information (belief-information - 5)
              ]
            ])
        ]
        [ ;; else-commands - This is any agent who is of middle to high or middle to low perceived and factual knowledge
          (ifelse
            for-topic = 2 [
              if (coin - (true-exposed)) < 300 [ ;; Against and middle range perceived and factual knowledge means not likely to share or increase belief.
                set belief-information (belief-information + 5)
                set factual-knowledge (factual-knowledge + 5)
              ]
              if (coin - (true-exposed)) >= 300 [
                set belief-information (belief-information - 5) ;; Do not believe in the misinformation
              ]
            ]
            for-topic = 1 [
              if (coin - (true-exposed)) < 700 [ ;; For and middle range perceived and factual knowledge means not likely to share or increase belief.
                set belief-information (belief-information + 5)
                set factual-knowledge (factual-knowledge + 5)
              ]
              if (coin - (true-exposed)) >= 700 [
                set belief-information (belief-information - 5) ;; Do not believe in the misinformation
              ]
            ]
            for-topic = 0 [
              if (coin - (true-exposed)) < 500 [ ;; Undecided and middle range perceived and factual knowledge means not likely to share or increase belief.
                set belief-information (belief-information + 5)
                set factual-knowledge (factual-knowledge + 5)
              ]
              if (coin - (true-exposed)) >= 500 [
                set belief-information (belief-information - 5) ;; Do not believe in the misinformation
              ]
            ])
        ])
        ]
    if belief-information > 800 and share-information? = false and belief-misinformation < 300[
      set share-information? true
      set color green
    ]

    ;; Change belief
    if for-topic = 1 and belief-information < 150 and belief-misinformation > 500 [
      set for-topic 2
    ]
    if for-topic = 1 and belief-information < 150 and belief-misinformation < 500 [
      set for-topic 0
    ]
;;    if belief-misinformation <= 50 and share-misinformation? = true  [
;;      set share-misinformation? false
;;      set color blue
;;  ]
  ]
end

;; TODO IMPLEMENTATION
;;
;; 1. If someone 'falls' for misinformation then do they change there belief?
;; 2. If someone if for, against, neutral on some topic should determine the initial belief they have in both the true and mis information
;; 3. Am I assuming that they are 'competing campaigns' -> is the true information directly contradictory to the misinformation therefor implying that if you share a you would not share or believe b.
;; 4. How do I reset the plot?
;; 5. When I add the true information simulation they exposure goes to 100 straight away!
;; 6. If we assuming competing campaign then we should make a couple of assumptions... if I am 'for' a topic and my belief falls below some freshhold should I become 'undecided' or 'against'?
;; 7. I now need to create some experiments! Ask the model questions... How does increasing the number of agent with perceived knowledge and low factual knowledge effect share and belief in information?
;;    - How does increasing factual knowledge over the population effect the information spread?
;;    - How does tweaking knowledge gaps etc effect the overall opinion climate (for, against, undecided)




; Copyright 2008 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
705
10
1390
696
-1
-1
16.5122
1
10
1
1
1
0
1
1
1
-20
20
-20
20
1
1
1
ticks
30.0

BUTTON
97
139
166
179
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
27
182
419
381
Network Status
Ticks
% of nodes
0.0
1500.0
0.0
100.0
true
true
"" ""
PENS
"mis-shared" 1.0 0 -2674135 true "" "plot (count turtles with [share-misinformation? = true]) / (count turtles) * 100"
"true-shared" 1.0 0 -7500403 true "" "plot (count turtles with [share-information? = true]) / (count turtles) * 100"

SLIDER
30
32
216
65
media-agents
media-agents
0
100
4.0
1
1
NIL
HORIZONTAL

BUTTON
28
139
94
179
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
24
387
421
602
Mis-beliefe
Tick
Agents
0.0
1500.0
0.0
100.0
true
true
"" ""
PENS
"mis-belief" 1.0 0 -2674135 true "" "plot ((count (turtles with [belief-misinformation > 500]) / count turtles) * 100)"
"true-belief" 1.0 0 -1184463 true "" "plot (((count turtles with [belief-information > 500]) / (count turtles)) * 100)"
"no mis-belief" 1.0 0 -7500403 true "" "plot ((count (turtles with [belief-misinformation < 500]) / count turtles) * 100)"
"no true-belief" 1.0 0 -955883 true "" "plot ((count (turtles with [belief-information < 500]) / count turtles) * 100)"

SWITCH
25
608
128
641
layout?
layout?
0
1
-1000

SWITCH
25
643
128
676
plot?
plot?
0
1
-1000

MONITOR
449
187
599
232
NIL
count turtles
17
1
11

SLIDER
30
69
217
102
agents
agents
0
1500
235.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model demonstrates the spread of a virus through a network.  Although the model is somewhat abstract, one interpretation is that each node represents a computer, and we are modeling the progress of a computer virus (or worm) through this network.  Each node may be in one of three states:  susceptible, infected, or resistant.  In the academic literature such a model is sometimes referred to as an SIR model for epidemics.

## HOW IT WORKS

Each time step (tick), each infected node (colored red) attempts to infect all of its neighbors.  Susceptible neighbors (colored green) will be infected with a probability given by the VIRUS-SPREAD-CHANCE slider.  This might correspond to the probability that someone on the susceptible system actually executes the infected email attachment.
Resistant nodes (colored gray) cannot be infected.  This might correspond to up-to-date antivirus software and security patches that make a computer immune to this particular virus.

Infected nodes are not immediately aware that they are infected.  Only every so often (determined by the VIRUS-CHECK-FREQUENCY slider) do the nodes check whether they are infected by a virus.  This might correspond to a regularly scheduled virus-scan procedure, or simply a human noticing something fishy about how the computer is behaving.  When the virus has been detected, there is a probability that the virus will be removed (determined by the RECOVERY-CHANCE slider).

If a node does recover, there is some probability that it will become resistant to this virus in the future (given by the GAIN-RESISTANCE-CHANCE slider).

When a node becomes resistant, the links between it and its neighbors are darkened, since they are no longer possible vectors for spreading the virus.

## HOW TO USE IT

Using the sliders, choose the NUMBER-OF-NODES and the AVERAGE-NODE-DEGREE (average number of links coming out of each node).

The network that is created is based on proximity (Euclidean distance) between nodes.  A node is randomly chosen and connected to the nearest node that it is not already connected to.  This process is repeated until the network has the correct number of links to give the specified average node degree.

The INITIAL-OUTBREAK-SIZE slider determines how many of the nodes will start the simulation infected with the virus.

Then press SETUP to create the network.  Press GO to run the model.  The model will stop running once the virus has completely died out.

The VIRUS-SPREAD-CHANCE, VIRUS-CHECK-FREQUENCY, RECOVERY-CHANCE, and GAIN-RESISTANCE-CHANCE sliders (discussed in "How it Works" above) can be adjusted before pressing GO, or while the model is running.

The NETWORK STATUS plot shows the number of nodes in each state (S, I, R) over time.

## THINGS TO NOTICE

At the end of the run, after the virus has died out, some nodes are still susceptible, while others have become immune.  What is the ratio of the number of immune nodes to the number of susceptible nodes?  How is this affected by changing the AVERAGE-NODE-DEGREE of the network?

## THINGS TO TRY

Set GAIN-RESISTANCE-CHANCE to 0%.  Under what conditions will the virus still die out?   How long does it take?  What conditions are required for the virus to live?  If the RECOVERY-CHANCE is bigger than 0, even if the VIRUS-SPREAD-CHANCE is high, do you think that if you could run the model forever, the virus could stay alive?

## EXTENDING THE MODEL

The real computer networks on which viruses spread are generally not based on spatial proximity, like the networks found in this model.  Real computer networks are more often found to exhibit a "scale-free" link-degree distribution, somewhat similar to networks created using the Preferential Attachment model.  Try experimenting with various alternative network structures, and see how the behavior of the virus differs.

Suppose the virus is spreading by emailing itself out to everyone in the computer's address book.  Since being in someone's address book is not a symmetric relationship, change this model to use directed links instead of undirected links.

Can you model multiple viruses at the same time?  How would they interact?  Sometimes if a computer has a piece of malware installed, it is more vulnerable to being infected by more malware.

Try making a model similar to this one, but where the virus has the ability to mutate itself.  Such self-modifying viruses are a considerable threat to computer security, since traditional methods of virus signature identification may not work against them.  In your model, nodes that become immune may be reinfected if the virus has mutated to become significantly different than the variant that originally infected the node.

## RELATED MODELS

Virus, Disease, Preferential Attachment, Diffusion on a Directed Network

## NETLOGO FEATURES

Links are used for modeling the network.  The `layout-spring` primitive is used to position the nodes and links such that the structure of the network is visually clear.

Though it is not used in this model, there exists a network extension for NetLogo that you can download at: https://github.com/NetLogo/NW-Extension.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Stonedahl, F. and Wilensky, U. (2008).  NetLogo Virus on a Network model.  http://ccl.northwestern.edu/netlogo/models/VirusonaNetwork.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2008 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2008 Cite: Stonedahl, F. -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
